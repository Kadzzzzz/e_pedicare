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

    # Base de données
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URI', 'sqlite:///{os.path.join(DATABASE_DIR, "epedicare.db")}')
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=60)

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