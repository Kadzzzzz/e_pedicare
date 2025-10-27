from .user import create_user_model
from .child import create_child_model
from .session import create_session_model


def init_models(db):

    User = create_user_model(db)
    Child = create_child_model(db)
    ExperimentSession = create_session_model(db)

    return User, Child, ExperimentSession