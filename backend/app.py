from flask import Flask, jsonify, request
from flask_restful import Api, Resource
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity, get_jwt
from datetime import timedelta
import os
from dotenv import load_dotenv

# Charger les variables d'environnement
load_dotenv()

# Créer l'application
app = Flask(__name__)

# Configuration
app.config['SQLALCHEMY_DATABASE_URI'] = os.getenv('DATABASE_URI', 'sqlite:///epedicare.db')
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['JWT_SECRET_KEY'] = os.getenv('JWT_SECRET_KEY', 'dev-secret-key-change-in-production')
app.config['JWT_ACCESS_TOKEN_EXPIRES'] = timedelta(minutes=60)

# Initialiser les extensions
db = SQLAlchemy(app)
api = Api(app)
jwt = JWTManager(app)
CORS(app)

# Import des modèles
from models import init_models
User, Child, ExperimentSession = init_models(db)


#GESTIONNAIRES D'ERREURS JWT

@jwt.expired_token_loader
def expired_token_callback(jwt_header, jwt_payload):
    return jsonify({'message': 'Le token a expiré', 'error': 'token_expired'}), 401

@jwt.invalid_token_loader
def invalid_token_callback(error):
    return jsonify({'message': 'Token invalide', 'error': 'invalid_token'}), 401

@jwt.unauthorized_loader
def missing_token_callback(error):
    return jsonify({'message': 'Token requis', 'error': 'authorization_required'}), 401


# ENDPOINTS

class HelloWorld(Resource):
    def get(self):
        return {"message": "API e-PediCare v1.0", "version": "1.0.0", "status": "running"}


class Register(Resource):
    def post(self):
        data = request.get_json()
        
        if not data or not data.get('email') or not data.get('password') or not data.get('role'):
            return {'message': 'Email, mot de passe et rôle requis'}, 400
        
        email = data['email']
        password = data['password']
        role = data['role']
        
        if role not in ['parent', 'expert', 'admin']:
            return {'message': 'Rôle invalide'}, 400
        
        # Vérifier si existe
        if User.query.filter_by(email=email).first():
            return {'message': 'Email déjà utilisé'}, 409
        
        # Créer
        new_user = User(email=email, role=role)
        new_user.set_password(password)
        db.session.add(new_user)
        db.session.commit()
        
        return {'message': 'Utilisateur créé', 'user': new_user.to_dict()}, 201


class Login(Resource):
    def post(self):
        data = request.get_json()
        
        if not data or not data.get('email') or not data.get('password'):
            return {'message': 'Email et mot de passe requis'}, 400
        
        email = data['email']
        password = data['password']
        
        # Chercher utilisateur
        user = User.query.filter_by(email=email).first()
        
        if not user or not user.check_password(password):
            return {'message': 'Email ou mot de passe incorrect'}, 401
        
        # Créer token
        access_token = create_access_token(
            identity=user.email,
            additional_claims={'role': user.role, 'user_id': user.id}
        )
        
        return {
            'message': 'Connexion réussie',
            'access_token': access_token,
            'user': user.to_dict()
        }, 200


class Profile(Resource):
    @jwt_required()
    def get(self):
        current_user_email = get_jwt_identity()
        jwt_data = get_jwt()
        
        user = User.query.filter_by(email=current_user_email).first()
        
        if not user:
            return {'message': 'Utilisateur non trouvé'}, 404
        
        return {
            'user': user.to_dict(),
            'jwt_data': {'role': jwt_data.get('role'), 'user_id': jwt_data.get('user_id')}
        }, 200


class ProtectedResource(Resource):
    @jwt_required()
    def get(self):
        current_user_email = get_jwt_identity()
        jwt_data = get_jwt()
        return {'message': f'Bienvenue {current_user_email}', 'role': jwt_data.get('role')}, 200


class AdminOnly(Resource):
    @jwt_required()
    def get(self):
        jwt_data = get_jwt()
        if jwt_data.get('role') != 'admin':
            return {'message': 'Accès refusé. Rôle admin requis.'}, 403
        return {'message': 'Bienvenue dans la zone admin'}, 200


# ENREGISTREMENT DES ROUTES

api.add_resource(HelloWorld, '/api/hello')
api.add_resource(Register, '/api/auth/register')
api.add_resource(Login, '/api/auth/login')
api.add_resource(Profile, '/api/auth/profile')
api.add_resource(ProtectedResource, '/api/protected')
api.add_resource(AdminOnly, '/api/admin')


# INITIALISATION DB

def init_db():
    with app.app_context():
        db.create_all()
        print("✅ Base de données initialisée")
        
        admin = User.query.filter_by(role='admin').first()
        if not admin:
            admin = User(email='admin@epedicare.fr', role='admin')
            admin.set_password('admin123')
            db.session.add(admin)
            db.session.commit()
            print("✅ Admin créé (admin@epedicare.fr / admin123)")


# DÉMARRAGE

if __name__ == '__main__':
    init_db()
    app.run(debug=True, host='0.0.0.0', port=5000)
