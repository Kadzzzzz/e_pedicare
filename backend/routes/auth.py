from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity, get_jwt
from extensions import db

auth_bp = Blueprint('auth', __name__)


@auth_bp.route('/register', methods=['POST'])
def register():
    """Inscription d'un nouvel utilisateur"""
    User = current_app.User
    data = request.get_json()

    # Validation des données
    if not data or not data.get('email') or not data.get('password') or not data.get('role'):
        return jsonify({'message': 'Email, mot de passe et rôle requis'}), 400

    email = data['email']
    password = data['password']
    role = data['role']

    # Validation du rôle
    if role not in ['parent', 'expert', 'admin']:
        return jsonify({'message': 'Rôle invalide. Valeurs acceptées: parent, expert, admin'}), 400

    # Vérifier si l'utilisateur existe déjà
    if User.query.filter_by(email=email).first():
        return jsonify({'message': 'Cet email est déjà utilisé'}), 409

    # Créer le nouvel utilisateur
    new_user = User(email=email, role=role)
    new_user.set_password(password)

    try:
        db.session.add(new_user)
        db.session.commit()
        return jsonify({
            'message': 'Utilisateur créé avec succès',
            'user': new_user.to_dict()
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({'message': f'Erreur lors de la création: {str(e)}'}), 500


@auth_bp.route('/login', methods=['POST'])
def login():
    """Connexion d'un utilisateur"""
    User = current_app.User
    data = request.get_json()

    # Validation des données
    if not data or not data.get('email') or not data.get('password'):
        return jsonify({'message': 'Email et mot de passe requis'}), 400

    email = data['email']
    password = data['password']

    # Chercher l'utilisateur
    user = User.query.filter_by(email=email).first()

    # Vérifier les credentials
    if not user or not user.check_password(password):
        return jsonify({'message': 'Email ou mot de passe incorrect'}), 401

    # Créer le token JWT
    access_token = create_access_token(
        identity=user.email,
        additional_claims={
            'role': user.role,
            'user_id': user.id
        }
    )

    return jsonify({
        'message': 'Connexion réussie',
        'access_token': access_token,
        'user': user.to_dict()
    }), 200


@auth_bp.route('/profile', methods=['GET'])
@jwt_required()
def get_profile():
    """Récupérer le profil de l'utilisateur connecté"""
    User = current_app.User 
    current_user_email = get_jwt_identity()
    jwt_data = get_jwt()

    user = User.query.filter_by(email=current_user_email).first()

    if not user:
        return jsonify({'message': 'Utilisateur non trouvé'}), 404

    return jsonify({
        'user': user.to_dict(),
        'jwt_data': {
            'role': jwt_data.get('role'),
            'user_id': jwt_data.get('user_id')
        }
    }), 200


@auth_bp.route('/check', methods=['GET'])
@jwt_required()
def check_auth():
    """Vérifier si le token est valide"""
    current_user_email = get_jwt_identity()
    jwt_data = get_jwt()

    return jsonify({
        'authenticated': True,
        'email': current_user_email,
        'role': jwt_data.get('role'),
        'user_id': jwt_data.get('user_id')
    }), 200