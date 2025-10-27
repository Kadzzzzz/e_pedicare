from datetime import datetime

def create_child_model(db):

    class Child(db.Model):
        __tablename__ = 'children'

        id = db.Column(db.Integer, primary_key=True)
        name = db.Column(db.String(100), nullable=False)
        birthdate = db.Column(db.Date, nullable=False)
        parent_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=False)
        created_at = db.Column(db.DateTime, default=datetime.utcnow)

        sessions = db.relationship('ExperimentSession', backref='child', lazy=True)

        def get_age_months(self):
            today = datetime.now().date()
            months = (today.year - self.birthdate.year) * 12 + (today.month - self.birthdate.month)
            return months

        def to_dict(self):
            return {
                'id': self.id,
                'name': self.name,
                'birthdate': self.birthdate.isoformat(),
                'age_months': self.get_age_months(),
                'parent_id': self.parent_id,
                'created_at': self.created_at.isoformat() if self.created_at else None
            }

        def __repr__(self):
            return f'<Child {self.name}>'

    return Child


