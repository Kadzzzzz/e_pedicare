from flask import Flask, jsonify, send_from_directory
from flask_restful import Api
from config import config
from extensions import db, jwt, cors

# Créer l'application
app = Flask(__name__)

# Charger la configuration
config_name = 'development'
app.config.from_object(config[config_name])

# Initialiser les extensions
db.init_app(app)
api = Api(app)
jwt.init_app(app)
cors.init_app(app)

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

@app.route('/test')
def test_page():
    return send_from_directory('static', 'test.html')

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