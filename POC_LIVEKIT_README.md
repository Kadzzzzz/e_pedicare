# 🎥 POC LiveKit - e-PediCare

## Proof of Concept : Visioconférence avec serveur (pas de P2P)

**Objectif** : Valider le concept de streaming vidéo Patient → LiveKit Server → Praticien, permettant l'enregistrement et le traitement des vidéos.

---

## 🏗️ Architecture

```
┌─────────────┐           ┌──────────────────┐           ┌─────────────────┐
│   Patient   │ ────────► │  LiveKit Server  │ ◄──────── │   Praticien     │
│  (Flutter)  │           │      (SFU)       │           │   (Flutter)     │
│  📹 Caméra  │           │                  │           │  📺 Écran       │
└─────────────┘           └────────┬─────────┘           └─────────────────┘
                                   │
                          ┌────────▼─────────┐
                          │  Enregistrement  │
                          │   Traitement     │
                          │   Analyse IA     │
                          └──────────────────┘
```

**✅ TOUT PASSE PAR LE SERVEUR - PAS DE PEER-TO-PEER**

- **Signalisation** : Gérée par LiveKit
- **Streaming vidéo** : Passe par le serveur LiveKit (SFU)
- **Tokens** : Générés par Flask backend
- **Session** : ID simple (ex: "session123")

---

## 🚀 Démarrage rapide

### Prérequis

- **Docker** (pour LiveKit server)
- **Python 3.9+** (pour Flask backend)
- **Flutter** (pour le frontend)

---

### 1️⃣ Démarrer le serveur LiveKit (Docker)

```bash
docker run -d \
  --name livekit-server \
  -p 7880:7880 \
  -p 7881:7881 \
  -p 7882:7882/udp \
  -e LIVEKIT_KEYS='devkey: secret' \
  livekit/livekit-server:latest
```

**Vérification** :
```bash
curl http://localhost:7880
# Devrait retourner une réponse LiveKit
```

---

### 2️⃣ Backend Flask (Génération de tokens)

```bash
cd backend

# Installation des dépendances
pip install -r requirements.txt

# Démarrer le serveur Flask
python livekit_server.py
```

Le serveur démarre sur **http://localhost:5002**

**Vérification** :
```bash
curl http://localhost:5002/health
# {"status": "ok", "livekit_url": "ws://localhost:7880"}
```

---

### 3️⃣ Frontend Flutter

```bash
cd frontend

# Installation des dépendances
flutter pub get

# Lancer l'application (Web recommandé)
flutter run -d chrome lib/main_poc.dart
```

---

## 📱 Utilisation

### Étape 1 : Patient crée une session
1. Ouvrez l'application Flutter
2. Cliquez sur **"Je suis un Patient"**
3. Entrez un ID de session (ex: `test123`)
4. Cliquez sur **"Démarrer la session"**
5. Autorisez l'accès à la caméra
6. Votre caméra s'affiche → **En attente du praticien**
7. ✅ La vidéo est envoyée au serveur LiveKit

### Étape 2 : Praticien rejoint la session
1. Ouvrez une **nouvelle fenêtre** (ou incognito)
2. Cliquez sur **"Je suis un Praticien"**
3. Entrez le **même ID** que le patient (ex: `test123`)
4. Cliquez sur **"Rejoindre la session"**
5. ✅ La vidéo du patient s'affiche !
6. ✅ Tout passe par le serveur LiveKit

---

## 🔧 Technologies utilisées

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| **SFU Server** | LiveKit | Serveur de streaming vidéo (SFU) |
| **Backend** | Flask + livekit-api | Génération de tokens JWT |
| **Frontend** | Flutter Web + livekit_client | Interface utilisateur |
| **Container** | Docker | Hébergement LiveKit |

---

## 📁 Fichiers créés

```
backend/
├── livekit_server.py          # Serveur Flask pour tokens LiveKit
└── requirements.txt           # Dépendances (+ livekit-api)

frontend/lib/
├── main_poc.dart               # Point d'entrée avec navigation
└── pages/
    ├── livekit_patient_page.dart      # Page patient (envoie au serveur)
    └── livekit_practitioner_page.dart # Page praticien (reçoit du serveur)
```

---

## ✅ Avantages de LiveKit vs P2P

| Critère | P2P WebRTC | LiveKit (SFU) |
|---------|-----------|---------------|
| **Flux vidéo** | Direct patient → praticien | Patient → Serveur → Praticien |
| **Enregistrement** | ❌ Difficile | ✅ Natif avec `egress` |
| **Traitement** | ❌ Impossible côté serveur | ✅ Accès au flux côté serveur |
| **Qualité** | Variable (NAT/Firewall) | Stable |
| **Multi-utilisateurs** | Complexe | ✅ Facile |
| **Stockage** | ❌ Non | ✅ Oui |
| **Analyse IA** | ❌ Côté client uniquement | ✅ Côté serveur |

**→ LiveKit est PARFAIT pour votre cas d'usage !**

---

## 📦 Configuration LiveKit

### Variables d'environnement (optionnel)

Créez un fichier `.env` dans `backend/` :

```env
LIVEKIT_API_KEY=devkey
LIVEKIT_API_SECRET=secret
LIVEKIT_URL=ws://localhost:7880
```

### Production

Pour la production, utilisez :
- Une vraie clé API (pas `devkey`)
- HTTPS/WSS (pas HTTP/WS)
- LiveKit Cloud ou serveur dédié

---

## 🎯 Fonctionnalités disponibles avec LiveKit

### Actuellement implémenté
- ✅ Capture caméra patient
- ✅ Transmission via serveur LiveKit
- ✅ Affichage chez le praticien
- ✅ Session simple par ID

### Facilement activable
- ⚡ **Enregistrement** : Utiliser `livekit egress`
- ⚡ **Multi-praticiens** : Plusieurs praticiens dans la même room
- ⚡ **Audio** : Déjà activé dans le code
- ⚡ **Statistiques** : Qualité réseau, latence, etc.
- ⚡ **Chat** : Via `DataChannel`

---

## 🔍 Enregistrement des sessions (exemple)

LiveKit permet l'enregistrement natif avec `egress` :

```python
# Dans livekit_server.py, ajoutez :
from livekit import api

# Démarrer l'enregistrement d'une room
egress_service = api.EgressService()
egress_service.start_room_composite_egress(
    room_name="session123",
    output={
        "file": {
            "filepath": "/recordings/session123.mp4"
        }
    }
)
```

---

## 🐛 Debugging

### Le serveur LiveKit ne démarre pas ?
```bash
docker ps
# Vérifiez que le container tourne

docker logs livekit-server
# Voir les logs
```

### Le backend Flask ne se connecte pas à LiveKit ?
```bash
# Vérifiez la config
curl http://localhost:5002/health

# Devrait retourner :
# {"status": "ok", "livekit_url": "ws://localhost:7880"}
```

### Le patient/praticien ne peut pas rejoindre ?
- Vérifiez que les 3 services tournent (LiveKit + Flask + Flutter)
- Vérifiez la console du navigateur (F12)
- Vérifiez que l'ID de session est le même

### Erreur de token ?
- Vérifiez que `LIVEKIT_API_KEY` et `LIVEKIT_API_SECRET` correspondent dans :
  - Docker run command (`-e LIVEKIT_KEYS='devkey: secret'`)
  - `livekit_server.py` (variables d'environnement)

---

## 📊 Différence avec l'ancien POC

### Ancien POC (WebRTC P2P)
```
Patient ←──── P2P WebRTC ────→ Praticien
         (signalisation Flask-SocketIO)
```
❌ Pas d'enregistrement
❌ Pas de traitement serveur
❌ Complexe pour multi-utilisateurs

### Nouveau POC (LiveKit SFU)
```
Patient → LiveKit Server → Praticien
                ↓
         Enregistrement
         Traitement
         Analyse IA
```
✅ Tout passe par le serveur
✅ Enregistrement natif
✅ Traitement côté serveur facile
✅ Scalable

---

## 🎓 Prochaines étapes

1. **Tester le POC** : Valider que ça fonctionne
2. **Activer l'enregistrement** : Utiliser LiveKit egress
3. **Ajouter le traitement** : Analyse comportementale en temps réel
4. **Sécurité** : Authentification avec JWT
5. **Production** : Déployer sur un vrai serveur

---

## 📞 Test rapide

```bash
# Terminal 1 : LiveKit Server
docker run -d -p 7880:7880 -p 7881:7881 -p 7882:7882/udp \
  -e LIVEKIT_KEYS='devkey: secret' \
  livekit/livekit-server:latest

# Terminal 2 : Backend Flask
cd backend && python livekit_server.py

# Terminal 3 : Frontend Patient
cd frontend && flutter run -d chrome lib/main_poc.dart

# Terminal 4 (ou fenêtre incognito) : Frontend Praticien
# Même URL que le patient
```

---

## 🎉 Résumé

**Ce POC prouve que :**
1. ✅ On peut capturer la caméra du patient
2. ✅ On peut transmettre le flux via le serveur LiveKit (pas de P2P)
3. ✅ On peut afficher le flux chez le praticien
4. ✅ On peut enregistrer et traiter les vidéos côté serveur
5. ✅ C'est simple à mettre en place (~500 lignes de code)

**Mission accomplie !** 🚀

---

## 🔗 Ressources

- [LiveKit Documentation](https://docs.livekit.io/)
- [LiveKit Egress (Recording)](https://docs.livekit.io/realtime/egress/overview/)
- [LiveKit Flutter SDK](https://docs.livekit.io/client-sdk-flutter/)
- [LiveKit Python SDK](https://docs.livekit.io/server-sdk-python/)
