from flask import Blueprint, jsonify

index_bp = Blueprint('index', __name__)


@index_bp.route('/', methods=['GET'])
def index():
    return jsonify({
        'message': 'Bienvenue sur l\'API e-PediCare',
        'version': '1.0.0',
        'status': 'running',
        'endpoints': {
            'auth': '/api/auth',
            'documentation': 'Coming soon...'
        }
    }), 200


@index_bp.route('/health', methods=['GET'])
def health_check():
    """Vérifier que l'API fonctionne"""
    return jsonify({
        'status': 'healthy',
        'message': 'L\'API fonctionne correctement'
    }), 200