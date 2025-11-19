from livekit import AccessToken, VideoGrants

# --- PARAMÈTRES DE VOTRE SERVEUR DEV ---
# Clés par défaut du mode 'livekit-server --dev'
API_KEY = "devkey"
API_SECRET = "secret"
# La salle où le Client et le Praticien doivent se rencontrer
ROOM_NAME = "consultation_unique" 

# --- GÈNÈRATION DES TOKENS ---

# 1. TOKEN POUR LE CLIENT (Identity: client_1)
# Permissions: Peut publier la vidéo (caméra) et souscrire (voir le praticien)
grants_client = VideoGrants(
    room_join=True,
    room=ROOM_NAME,
    can_publish=True,
    can_subscribe=True
)
token_client = AccessToken(API_KEY, API_SECRET).with_grants(grants_client).to_jwt(
    identity="client_1",
    name="Client Page"
)

# 2. TOKEN POUR LE PRATICIEN (Identity: praticien_1)
# Permissions: Peut publier (si le praticien a besoin de sa vidéo) et souscrire (voir le client)
grants_praticien = VideoGrants(
    room_join=True,
    room=ROOM_NAME,
    can_publish=True,
    can_subscribe=True
)
token_praticien = AccessToken(API_KEY, API_SECRET).with_grants(grants_praticien).to_jwt(
    identity="praticien_1",
    name="Praticien Page"
)

# --- AFFICHAGE ---
print("===================================================")
print(f"SALLE UTILISÉE : {ROOM_NAME}")
print("===================================================")
print("\n🔑 TOKEN CLIENT (Identity: client_1) :")
print(token_client)
print("\n🔑 TOKEN PRATICIEN (Identity: praticien_1) :")
print(token_praticien)
print("===================================================")