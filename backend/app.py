from flask import Flask, jsonify, request
from flask_restful import Api, Resource
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy

app = Flask(__name__)
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///epedicare.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)
CORS(app)
api= Api(app)

from models import init_models
User, Child, ExperimentSession = init_models(db)

class HelloWorld(Resource):
    def get(self):
        return {"message": "API e-PediCare v1.0"}

api.add_resource(HelloWorld, '/')

def init_db():
    with app.app_context():
        db.create_all()
        print("Base de données initialisée")


if __name__ == '__main__':
    init_db()
    app.run(debug=True)