from flask import Flask, jsonify, request, send_from_directory
from flask_restful import Api
from livekit.api import AccessToken, VideoGrants
from config import config
from extensions import db, jwt, cors

app = Flask(__name__)

# Charger la configuration
config_name = 'development'
app.config.from_object(config[config_name])

# Initialiser les extensions
db.init_app(app)
api = Api(app)
jwt.init_app(app)
cors.init_app(app)

# LiveKit Cloud
LIVEKIT_API_KEY = "APImK8WCqNu4jzJ"  # ← Votre API Key
LIVEKIT_API_SECRET = "VZeKI9yzxINJfN8QD8eaZYp6fSXUgeQyzAeXGcfIGZmC"  # ← Votre API Secret
LIVEKIT_URL = "wss://epedicare-pnranm1s.livekit.cloud"  # ← Votre URL WebSocket

# Serveur LiveKit Local
# LIVEKIT_API_KEY = "devkey"
# LIVEKIT_API_SECRET = "secret"
# LIVEKIT_URL = "ws://localhost:7880"

LIVEKIT_ROOM_NAME = "consultation_unique"  # Nom de la salle partagée


# Fonction de génération de token LiveKit
def generate_livekit_token(identity: str) -> str:
    """Génère un token JWT LiveKit pour l'identité donnée."""

    token = AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET) \
        .with_identity(identity) \
        .with_name(identity) \
        .with_grants(VideoGrants(
        room_join=True,
        room=LIVEKIT_ROOM_NAME,
        can_publish=True,
        can_subscribe=True
    ))

    return token.to_jwt()


# Import et initialisation des modèles dans le contexte de l'app
with app.app_context():
    from models import init_models

    User, Child, ExperimentSession = init_models(db)

    # Rendre les modèles disponibles globalement
    app.User = User
    app.Child = Child
    app.ExperimentSession = ExperimentSession


# --- ROUTES LIVEKIT ---
@app.route('/api/token', methods=['POST'])
def get_livekit_token():
    """Route appelée par Flutter pour obtenir un token LiveKit."""
    try:
        data = request.get_json()

        if not data:
            return jsonify({"error": "No JSON data provided"}), 400

        identity = data.get('identity')

        if not identity:
            return jsonify({"error": "Identity is required"}), 400

        token = generate_livekit_token(identity)
        app.logger.info(f"Token LiveKit généré pour: {identity}")

        return jsonify({
            "token": token,
            "url": LIVEKIT_URL  # Retourner l'URL pour que Flutter puisse l'utiliser
        }), 200

    except Exception as e:
        app.logger.error(f"Erreur lors de la génération du token LiveKit: {e}")
        return jsonify({"error": f"Erreur interne: {str(e)}"}), 500


@app.route('/api/livekit-info', methods=['GET'])
def get_livekit_info():
    """Retourne les informations de configuration LiveKit (sans les secrets)"""
    return jsonify({
        "url": LIVEKIT_URL,
        "room": LIVEKIT_ROOM_NAME,
        "configured": bool(LIVEKIT_API_KEY and LIVEKIT_API_SECRET)
    }), 200


@app.route('/hello', methods=['GET'])
def hello_message():
    """Route de test pour la connexion Flutter"""
    return jsonify({
        'message': 'Hello from Flask! La connexion a réussi.',
        'code': 200,
        'livekit_url': LIVEKIT_URL
    }), 200


@app.route('/test')
def test_page():
    """Page de test HTML"""
    return send_from_directory('static', 'test.html')


# Enregistrer les blueprints
from routes.index import index_bp
from routes.auth import auth_bp

app.register_blueprint(index_bp, url_prefix='/api')
app.register_blueprint(auth_bp, url_prefix='/api/auth')


# GESTIONNAIRES D'ERREURS JWT
@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    return jsonify({'message': 'Le token a expiré', 'error': 'token_expired'}), 401


@jwt.invalid_token_loader
def invalid_token_callback(error):
    return jsonify({'message': 'Token invalide', 'error': 'invalid_token'}), 401


@jwt.unauthorized_loader
def missing_token_callback(error):
    return jsonify({'message': 'Token requis', 'error': 'authorization_required'}), 401


# INITIALISATION DB
def init_db():
    with app.app_context():
        db.create_all()
        print("Base de données initialisée")

        admin = User.query.filter_by(role='admin').first()
        if not admin:
            admin = User(email='admin@epedicare.fr', role='admin')
            admin.set_password('admin123')
            db.session.add(admin)
            db.session.commit()
            print("Admin créé (admin@epedicare.fr / admin123)")


# DÉMARRAGE
if __name__ == '__main__':
    init_db()
    print("=" * 60)
    print("Flask Server démarré sur http://0.0.0.0:5000")
    print("=" * 60)
    print(f"LiveKit URL: {LIVEKIT_URL}")
    print(f"Salle: {LIVEKIT_ROOM_NAME}")
    print("Endpoints:")
    print("  - POST /api/token (génération token)")
    print("  - GET  /api/livekit-info (info configuration)")
    print("  - GET  /hello (test connexion)")
    print("=" * 60)
    app.run(debug=True, host='0.0.0.0', port=5000)