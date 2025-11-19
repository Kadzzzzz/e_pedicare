from flask import Flask, jsonify, request, send_from_directory # Ajout de 'request'
from flask_restful import Api
from livekit import AccessToken, VideoGrants
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

# --- 🚨 NOUVELLE CONFIGURATION LIVEKIT ---
# Utilisez ces clés car votre serveur LiveKit est lancé avec --dev
LIVEKIT_API_KEY = "devkey"
LIVEKIT_API_SECRET = "secret"
LIVEKIT_ROOM_NAME = "consultation_unique" # Nom de la salle partagée

# Fonction de génération de token LiveKit
def generate_livekit_token(identity: str) -> str:
    """Génère un token JWT LiveKit pour l'identité donnée."""
    grants = VideoGrants(
        room_join=True,
        room=LIVEKIT_ROOM_NAME,
        can_publish=True,
        can_subscribe=True
    )
    
    token = AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET).with_grants(grants).to_jwt(
        identity=identity,
        name=identity
    )
    return token


# Import et initialisation des modèles dans le contexte de l'app
with app.app_context():
     from models import init_models

     User, Child, ExperimentSession = init_models(db)

 # Rendre les modèles disponibles globalement
app.User = User
app.Child = Child
app.ExperimentSession = ExperimentSession

# Enregistrer les routes
from routes.index import index_bp
from routes.auth import auth_bp

app.register_blueprint(index_bp, url_prefix='/api')
app.register_blueprint(auth_bp, url_prefix='/api/auth')

# --- 🚨 NOUVEL ENDPOINT POUR LIVEKIT ---
@app.route('/api/token', methods=['POST'])
def get_livekit_token():
    """Route appelée par Flutter pour obtenir un token LiveKit."""
    data = request.get_json()
    identity = data.get('identity') # Attend 'client_1' ou 'praticien_1'

    if not identity:
        # Si 'identity' est manquant, renvoie une erreur
        return jsonify({"error": "Identity is required"}), 400

    try:
        token = generate_livekit_token(identity)
        # Renvoie le token à l'application Flutter
        return jsonify({"token": token}), 200 
    except Exception as e:
        app.logger.error(f"Erreur lors de la génération du token LiveKit: {e}")
        return jsonify({"error": "Erreur interne lors de la création du token"}), 500


@app.route('/test')
def test_page():
    # ... (code existant) ...
     return send_from_directory('static', 'test.html')

@app.route('/hello', methods=['GET'])
def hello_message():
    # ... (code existant) ...
     """Route de test pour la connexion Flutter"""
     return jsonify({
        # Le client Flutter attend cette clé 'message' !
        'message': 'Hello from Flask! La connexion a réussi.', 
        'code': 200
    }), 200
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
    app.run(debug=True, host='0.0.0.0', port=5000)