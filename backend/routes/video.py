"""
Routes API pour la gestion des sessions vidéo LiveKit
"""
from flask import Blueprint, request, jsonify, current_app
from livekit import api
from datetime import datetime, timedelta

video_bp = Blueprint('video', __name__, url_prefix='/api/video')

# Stockage en mémoire des sessions actives (pour le POC)
# En production, utilisez Redis ou une base de données
active_sessions = {}


@video_bp.route('/create-session', methods=['POST'])
def create_session():
    """
    Créer une nouvelle session vidéo (POC - sans authentification)

    Body JSON:
        - room_name: Nom de la room LiveKit (ex: "session-parent-123")
        - child_id: ID de l'enfant (optionnel pour POC)

    Returns:
        - room_name: Nom de la room créée
        - livekit_url: URL du serveur LiveKit
        - token: Token pour le créateur (parent)
        - session_id: ID de session pour référence
    """
    try:
        data = request.get_json()
        room_name = data.get('room_name')
        child_id = data.get('child_id')

        if not room_name:
            return jsonify({'error': 'room_name requis'}), 400

        # Pour le POC, utiliser un ID générique
        current_user = 'poc-user'

        # Générer un token LiveKit pour le parent/client
        token = api.AccessToken(
            current_app.config['LIVEKIT_API_KEY'],
            current_app.config['LIVEKIT_API_SECRET']
        )

        # Configurer les permissions du token
        # Le client peut publier vidéo et audio
        token.with_identity(f"parent-{current_user}") \
             .with_name(f"Parent {current_user}") \
             .with_grants(api.VideoGrants(
                 room_join=True,
                 room=room_name,
                 can_publish=True,
                 can_subscribe=True,
             ))

        # Token valide pour 6 heures
        token.with_ttl(timedelta(hours=6))

        # Sauvegarder la session
        session_id = f"{room_name}-{datetime.now().timestamp()}"
        active_sessions[session_id] = {
            'room_name': room_name,
            'child_id': child_id,
            'created_by': current_user,
            'created_at': datetime.now().isoformat(),
            'participants': []
        }

        return jsonify({
            'session_id': session_id,
            'room_name': room_name,
            'livekit_url': current_app.config['LIVEKIT_URL'],
            'token': token.to_jwt(),
            'message': 'Session créée avec succès'
        }), 201

    except Exception as e:
        current_app.logger.error(f"Erreur création session: {str(e)}")
        return jsonify({'error': f'Erreur serveur: {str(e)}'}), 500


@video_bp.route('/join-session', methods=['POST'])
def join_session():
    """
    Rejoindre une session vidéo existante (POC - sans authentification)

    Body JSON:
        - room_name: Nom de la room à rejoindre
        - participant_name: Nom du participant (ex: "Dr. Martin")

    Returns:
        - livekit_url: URL du serveur LiveKit
        - token: Token pour rejoindre la room
        - room_name: Nom de la room
    """
    try:
        data = request.get_json()
        room_name = data.get('room_name')
        participant_name = data.get('participant_name', 'Participant')

        if not room_name:
            return jsonify({'error': 'room_name requis'}), 400

        # Pour le POC, utiliser un ID générique
        current_user = 'poc-practitioner'

        # Générer un token LiveKit pour le praticien
        token = api.AccessToken(
            current_app.config['LIVEKIT_API_KEY'],
            current_app.config['LIVEKIT_API_SECRET']
        )

        # Le praticien peut voir et écouter, mais pas forcément publier
        # (pour le POC, on autorise quand même la publication)
        token.with_identity(f"practitioner-{current_user}") \
             .with_name(participant_name) \
             .with_grants(api.VideoGrants(
                 room_join=True,
                 room=room_name,
                 can_publish=True,  # Pour envoyer des stimuli plus tard
                 can_subscribe=True,  # Pour recevoir la vidéo du client
             ))

        token.with_ttl(timedelta(hours=6))

        return jsonify({
            'room_name': room_name,
            'livekit_url': current_app.config['LIVEKIT_URL'],
            'token': token.to_jwt(),
            'participant_name': participant_name,
            'message': 'Token généré avec succès'
        }), 200

    except Exception as e:
        current_app.logger.error(f"Erreur rejoindre session: {str(e)}")
        return jsonify({'error': f'Erreur serveur: {str(e)}'}), 500


@video_bp.route('/sessions/active', methods=['GET'])
def get_active_sessions():
    """
    Obtenir la liste des sessions actives

    Returns:
        Liste des sessions avec leurs informations
    """
    try:
        # Filtrer les sessions de plus de 6 heures (expirées)
        current_time = datetime.now()
        valid_sessions = {}

        for session_id, session in active_sessions.items():
            created_at = datetime.fromisoformat(session['created_at'])
            if (current_time - created_at).total_seconds() < 21600:  # 6 heures
                valid_sessions[session_id] = session

        # Mettre à jour le dictionnaire
        active_sessions.clear()
        active_sessions.update(valid_sessions)

        return jsonify({
            'sessions': list(active_sessions.values()),
            'count': len(active_sessions)
        }), 200

    except Exception as e:
        current_app.logger.error(f"Erreur récupération sessions: {str(e)}")
        return jsonify({'error': f'Erreur serveur: {str(e)}'}), 500


@video_bp.route('/end-session', methods=['POST'])
def end_session():
    """
    Terminer une session vidéo

    Body JSON:
        - room_name: Nom de la room à terminer
    """
    try:
        data = request.get_json()
        room_name = data.get('room_name')

        if not room_name:
            return jsonify({'error': 'room_name requis'}), 400

        # Chercher et supprimer la session
        session_to_remove = None
        for session_id, session in active_sessions.items():
            if session['room_name'] == room_name:
                session_to_remove = session_id
                break

        if session_to_remove:
            del active_sessions[session_to_remove]
            return jsonify({'message': 'Session terminée avec succès'}), 200
        else:
            return jsonify({'message': 'Session non trouvée'}), 404

    except Exception as e:
        current_app.logger.error(f"Erreur fin session: {str(e)}")
        return jsonify({'error': f'Erreur serveur: {str(e)}'}), 500
