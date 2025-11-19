"""
Serveur LiveKit ultra-simple pour POC
- Génère des tokens d'accès pour patient et praticien
- Tout le flux vidéo passe par le serveur LiveKit (pas de P2P)
- Permet l'enregistrement et le traitement ultérieur
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from livekit import api
import os

app = Flask(__name__)
CORS(app, resources={r"/*": {"origins": "*"}})

# Configuration LiveKit
# À modifier selon votre installation LiveKit
LIVEKIT_API_KEY = os.getenv('LIVEKIT_API_KEY', 'devkey')
LIVEKIT_API_SECRET = os.getenv('LIVEKIT_API_SECRET', 'secret')
LIVEKIT_URL = os.getenv('LIVEKIT_URL', 'ws://localhost:7880')

@app.route('/health')
def health():
    return jsonify({
        'status': 'ok',
        'livekit_url': LIVEKIT_URL
    })

@app.route('/token', methods=['POST'])
def get_token():
    """
    Génère un token LiveKit pour un participant

    Body JSON:
    {
        "room_name": "session123",
        "participant_name": "patient" ou "praticien",
        "role": "patient" ou "practitioner"
    }
    """
    try:
        data = request.get_json()
        room_name = data.get('room_name')
        participant_name = data.get('participant_name')
        role = data.get('role', 'participant')

        if not room_name or not participant_name:
            return jsonify({
                'error': 'room_name et participant_name requis'
            }), 400

        # Créer le token avec les permissions appropriées
        token = api.AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET) \
            .with_identity(participant_name) \
            .with_name(participant_name) \
            .with_grants(api.VideoGrants(
                room_join=True,
                room=room_name,
                can_publish=True,  # Peut publier audio/vidéo
                can_subscribe=True,  # Peut s'abonner aux flux des autres
            ))

        jwt_token = token.to_jwt()

        print(f"✅ Token généré pour {participant_name} dans la room {room_name}")

        return jsonify({
            'token': jwt_token,
            'url': LIVEKIT_URL,
            'room_name': room_name,
            'participant_name': participant_name
        })

    except Exception as e:
        print(f"❌ Erreur génération token: {e}")
        return jsonify({'error': str(e)}), 500

@app.route('/rooms', methods=['GET'])
def list_rooms():
    """Liste les rooms actives (optionnel pour debug)"""
    try:
        # Vous pouvez utiliser l'API LiveKit pour lister les rooms
        # Pour ce POC, on retourne juste un message
        return jsonify({
            'message': 'Utilisez le LiveKit CLI ou dashboard pour voir les rooms'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print("=" * 60)
    print("🚀 Serveur LiveKit démarré")
    print("=" * 60)
    print(f"📡 API URL: http://localhost:5002")
    print(f"🎥 LiveKit URL: {LIVEKIT_URL}")
    print(f"🔑 API Key: {LIVEKIT_API_KEY}")
    print("=" * 60)
    print("")
    print("⚠️  IMPORTANT: Assurez-vous que LiveKit server tourne:")
    print("   docker run -d -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \\")
    print("     -e LIVEKIT_KEYS='devkey: secret' \\")
    print("     livekit/livekit-server:latest")
    print("=" * 60)

    app.run(debug=True, host='0.0.0.0', port=5002)
