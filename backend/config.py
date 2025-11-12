import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

# Chemin absolu vers le dossier database
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
DATABASE_DIR = os.path.join(BASE_DIR, 'database')

# Créer le dossier database s'il n'existe pas
os.makedirs(DATABASE_DIR, exist_ok=True)

class Config:
    """Configuration de base"""

    # Base de données - chemin relatif simple pour SQLite
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URI', 'sqlite:///epedicare.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT - IMPORTANT : Valeur par défaut pour le développement
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-key-change-in-production-12345')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=60)

    # LiveKit Configuration
    # Pour le POC, créez un compte gratuit sur https://livekit.io/cloud
    # Puis récupérez vos clés API depuis le dashboard
    LIVEKIT_URL = os.getenv('LIVEKIT_URL', 'wss://your-project.livekit.cloud')
    LIVEKIT_API_KEY = os.getenv('LIVEKIT_API_KEY', 'your-api-key')
    LIVEKIT_API_SECRET = os.getenv('LIVEKIT_API_SECRET', 'your-api-secret')

class DevelopmentConfig(Config):
    """Configuration pour le développement"""
    DEBUG = True


class ProductionConfig(Config):
    """Configuration pour la production"""
    DEBUG = False
    # En production, ces valeurs DOIVENT venir de variables d'environnement
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URI')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY')


# Dictionnaire de configuration
config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}