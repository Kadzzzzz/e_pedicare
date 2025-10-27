from datetime import datetime

def create_session_model(db):

    class ExperimentSession(db.Model):
        __tablename__ = 'experiment_sessions'

        id = db.Column(db.Integer, primary_key=True)
        child_id = db.Column(db.Integer, db.ForeignKey('children.id'), nullable=False)
        expert_id = db.Column(db.Integer, db.ForeignKey('users.id'), nullable=True)
        video_path = db.Column(db.String(200), nullable=True)
        status = db.Column(db.String(20), default='pending')
        started_at = db.Column(db.DateTime, nullable=True)
        completed_at = db.Column(db.DateTime, nullable=True)
        notes = db.Column(db.Text, nullable=True)
        created_at = db.Column(db.DateTime, default=datetime.utcnow)

        def get_duration_minutes(self):
            if self.started_at and self.completed_at:
                duration = self.completed_at - self.started_at
                return int(duration.total_seconds() / 60)
            return None

        def to_dict(self):
            return {
                'id': self.id,
                'child_id': self.child_id,
                'expert_id': self.expert_id,
                'video_path': self.video_path,
                'status': self.status,
                'started_at': self.started_at.isoformat() if self.started_at else None,
                'completed_at': self.completed_at.isoformat() if self.completed_at else None,
                'notes': self.notes,
                'created_at': self.created_at.isoformat() if self.created_at else None
            }

        def __repr__(self):
            return f'<Session {self.id} - {self.status}>'

    return ExperimentSession