from datetime import datetime
from werkzeug.security import generate_password_hash, check_password_hash

def create_user_model(db):

    class User(db.Model):
        __tablename__ = 'users'

        id = db.Column(db.Integer, primary_key=True)
        email = db.Column(db.String(100), unique=True, nullable=False)
        password_hash = db.Column(db.String(200), nullable=False)
        role = db.Column(db.String(20), nullable=False)
        created_at = db.Column(db.DateTime, default=datetime.utcnow)

        children = db.relationship('Child', backref='parent', lazy=True)
        sessions_as_expert = db.relationship('ExperimentSession', backref='expert', lazy=True,
                                             foreign_keys='ExperimentSession.expert_id')

        def set_password(self, password):
            self.password_hash = generate_password_hash(password)

        def check_password(self, password):
            return check_password_hash(self.password_hash, password)

        def to_dict(self):
            return {
                'id': self.id,
                'email': self.email,
                'role': self.role,
                'created_at': self.created_at.isoformat() if self.created_at else None
            }

        def __repr__(self):
            return f'<User {self.email}>'

    return User