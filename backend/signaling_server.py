"""
Serveur de signalisation WebRTC ultra-simple
- Pas de base de données
- Pas de système de session complexe
- Juste un relais de messages WebRTC entre patient et praticien
"""

from flask import Flask
from flask_socketio import SocketIO, emit, join_room, leave_room
from flask_cors import CORS

app = Flask(__name__)
app.config['SECRET_KEY'] = 'dev-secret-key-change-in-prod'
CORS(app, resources={r"/*": {"origins": "*"}})
socketio = SocketIO(app, cors_allowed_origins="*")

# Dictionnaire simple pour suivre les connexions
# Format: {session_id: {'patient': socket_id, 'practitioner': socket_id}}
sessions = {}

@socketio.on('connect')
def handle_connect():
    print(f'Client connecté: {request.sid}')
    emit('connected', {'sid': request.sid})

@socketio.on('disconnect')
def handle_disconnect():
    print(f'Client déconnecté: {request.sid}')
    # Nettoyer les sessions
    for session_id, participants in list(sessions.items()):
        if participants.get('patient') == request.sid or participants.get('practitioner') == request.sid:
            # Notifier l'autre participant
            if participants.get('patient') == request.sid and participants.get('practitioner'):
                emit('peer_disconnected', room=participants['practitioner'])
            elif participants.get('practitioner') == request.sid and participants.get('patient'):
                emit('peer_disconnected', room=participants['patient'])
            # Supprimer la session
            del sessions[session_id]

@socketio.on('join_as_patient')
def handle_join_patient(data):
    """Patient rejoint une session avec un ID"""
    session_id = data.get('session_id')
    if not session_id:
        emit('error', {'message': 'session_id requis'})
        return

    # Créer ou rejoindre la session
    if session_id not in sessions:
        sessions[session_id] = {}

    sessions[session_id]['patient'] = request.sid
    join_room(session_id)

    print(f'Patient {request.sid} a rejoint la session {session_id}')
    emit('joined', {'role': 'patient', 'session_id': session_id})

    # Notifier le praticien si présent
    if 'practitioner' in sessions[session_id]:
        emit('patient_joined', {'session_id': session_id},
             room=sessions[session_id]['practitioner'])

@socketio.on('join_as_practitioner')
def handle_join_practitioner(data):
    """Praticien rejoint une session existante"""
    session_id = data.get('session_id')
    if not session_id:
        emit('error', {'message': 'session_id requis'})
        return

    # Créer ou rejoindre la session
    if session_id not in sessions:
        sessions[session_id] = {}

    sessions[session_id]['practitioner'] = request.sid
    join_room(session_id)

    print(f'Praticien {request.sid} a rejoint la session {session_id}')
    emit('joined', {'role': 'practitioner', 'session_id': session_id})

    # Notifier le patient si présent
    if 'patient' in sessions[session_id]:
        emit('practitioner_joined', {'session_id': session_id},
             room=sessions[session_id]['patient'])

@socketio.on('signal')
def handle_signal(data):
    """Relayer les messages de signalisation WebRTC (offer, answer, ice-candidate)"""
    session_id = data.get('session_id')
    signal_data = data.get('data')
    sender_role = data.get('sender_role')  # 'patient' ou 'practitioner'

    if not session_id or session_id not in sessions:
        emit('error', {'message': 'Session invalide'})
        return

    # Relayer vers l'autre participant
    session = sessions[session_id]
    if sender_role == 'patient' and 'practitioner' in session:
        emit('signal', {
            'data': signal_data,
            'from': 'patient'
        }, room=session['practitioner'])
        print(f'Signal relayé de patient vers praticien dans session {session_id}')

    elif sender_role == 'practitioner' and 'patient' in session:
        emit('signal', {
            'data': signal_data,
            'from': 'practitioner'
        }, room=session['patient'])
        print(f'Signal relayé de praticien vers patient dans session {session_id}')

@app.route('/health')
def health():
    return {'status': 'ok', 'sessions': len(sessions)}

if __name__ == '__main__':
    from flask import request
    print("🚀 Serveur de signalisation WebRTC démarré sur http://localhost:5001")
    print("📡 WebSocket disponible pour la signalisation")
    socketio.run(app, debug=True, host='0.0.0.0', port=5001)
