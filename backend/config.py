import os
from datetime import timedelta
from dotenv import load_dotenv

load_dotenv()

# Chemin ABSOLU
BASE_DIR = os.path.abspath(os.path.dirname(__file__))
DATABASE_DIR = os.path.join(BASE_DIR, 'database')
os.makedirs(DATABASE_DIR, exist_ok=True)

class Config:
    # IMPORTANT : Chemin ABSOLU, pas relatif
    db_path = os.path.join(DATABASE_DIR, "epedicare.db")
    db_path = db_path.replace('\\', '/')
    SQLALCHEMY_DATABASE_URI = f'sqlite:///{db_path}'  # Notez les 3 slashes
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY', 'dev-secret-key-change-in-production-12345')
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(minutes=60)

class DevelopmentConfig(Config):
    DEBUG = True

class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URI')
    JWT_SECRET_KEY = os.getenv('JWT_SECRET_KEY')

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'default': DevelopmentConfig
}