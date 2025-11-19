# 🎥 POC WebRTC - e-PediCare

## Proof of Concept ultra-simple : Visioconférence Patient → Praticien

**Objectif** : Valider le concept de streaming vidéo direct entre un patient et un praticien via WebRTC, sans complexité.

---

## 🏗️ Architecture

```
┌─────────────┐           ┌──────────────────┐           ┌─────────────────┐
│   Patient   │ ◄────────►│  Serveur Flask   │◄────────► │   Praticien     │
│  (Flutter)  │           │   + SocketIO     │           │   (Flutter)     │
│             │           │  (Signalisation) │           │                 │
│  📹 Caméra  │           └──────────────────┘           │  📺 Écran       │
└─────────────┘                                          └─────────────────┘
       │                                                          ▲
       └──────────────── WebRTC P2P Video Stream ───────────────┘
```

**Signalisation** : WebSocket (Flask-SocketIO) - Pour échanger les SDP et ICE candidates
**Streaming vidéo** : WebRTC P2P - Connexion directe entre navigateurs
**Session** : ID simple (ex: "session123")

---

## 🚀 Démarrage rapide

### 1️⃣ Backend (Serveur de signalisation)

```bash
# Installation des dépendances
cd backend
pip install flask flask-socketio flask-cors

# Démarrer le serveur
python signaling_server.py
```

Le serveur démarre sur **http://localhost:5001**

### 2️⃣ Frontend (Application Flutter)

```bash
# Installation des dépendances
cd frontend
flutter pub get

# Lancer l'application (Web recommandé pour le test)
flutter run -d chrome lib/main_poc.dart
```

**Note** : Pour tester avec 2 utilisateurs, ouvrez 2 fenêtres de navigateur.

---

## 📱 Utilisation

### Étape 1 : Patient crée une session
1. Cliquez sur **"Je suis un Patient"**
2. Entrez un ID de session (ex: `test123`)
3. Cliquez sur **"Démarrer la session"**
4. Autorisez l'accès à la caméra
5. Votre caméra s'affiche → **En attente du praticien**

### Étape 2 : Praticien rejoint la session
1. Cliquez sur **"Je suis un Praticien"** (dans une autre fenêtre)
2. Entrez le **même ID** que le patient (ex: `test123`)
3. Cliquez sur **"Rejoindre la session"**
4. La vidéo du patient s'affiche ! 🎉

---

## 🔧 Technologies utilisées

| Composant | Technologie | Rôle |
|-----------|-------------|------|
| **Backend** | Flask + Flask-SocketIO | Serveur de signalisation WebRTC |
| **Frontend** | Flutter Web | Interface utilisateur |
| **WebRTC** | flutter_webrtc | Streaming vidéo P2P |
| **WebSocket** | socket_io_client | Communication temps réel |

---

## 📁 Fichiers créés

```
backend/
└── signaling_server.py        # Serveur WebSocket ultra-simple

frontend/lib/
├── main_poc.dart               # Point d'entrée avec navigation
├── pages/
│   ├── poc_patient_page.dart      # Page patient (envoie vidéo)
│   └── poc_practitioner_page.dart # Page praticien (reçoit vidéo)
```

**Total : ~400 lignes de code** - C'est vraiment le minimum pour un POC WebRTC !

---

## ✅ Ce qui fonctionne

- ✅ Capture de la caméra du patient
- ✅ Transmission en temps réel vers le praticien
- ✅ Connexion via ID de session simple
- ✅ Signalisation WebRTC (SDP + ICE)
- ✅ Affichage du stream distant

## ❌ Ce qui n'est PAS implémenté (normal pour un POC)

- ❌ Authentification / Sécurité
- ❌ Enregistrement des sessions
- ❌ Chat texte
- ❌ Audio (peut être activé facilement)
- ❌ Gestion d'erreur avancée
- ❌ Multi-utilisateurs (1 patient = 1 praticien)
- ❌ TURN server (nécessaire pour certains NAT)

---

## 🐛 Debugging

### Le patient ne se connecte pas ?
- Vérifiez que le serveur Flask tourne sur le port 5001
- Vérifiez la console : `http://localhost:5001/health` doit retourner `{"status": "ok"}`

### Le praticien ne reçoit pas la vidéo ?
- Vérifiez que les deux utilisent le **même ID de session**
- Vérifiez la console du navigateur (F12) pour les logs WebRTC
- Le patient doit rejoindre **avant** le praticien (pour ce POC simple)

### Erreur de caméra ?
- Sur navigateur : Autorisez l'accès à la caméra
- Sur mobile : Ajoutez les permissions dans `AndroidManifest.xml` / `Info.plist`

---

## 🎯 Prochaines étapes possibles

Si ce POC fonctionne et valide le concept, on peut :

1. **Ajouter l'audio** (changer `enableAudio: true`)
2. **Améliorer la signalisation** (gérer les reconnexions)
3. **Ajouter un TURN server** (pour traverser les NAT restrictifs)
4. **Interface plus riche** (contrôles, qualité, statistiques)
5. **Sécurité** (authentification, chiffrement)

---

## 📞 Test

```bash
# Terminal 1 : Backend
cd backend && python signaling_server.py

# Terminal 2 : Frontend Patient
cd frontend && flutter run -d chrome lib/main_poc.dart

# Terminal 3 : Frontend Praticien (ou nouvelle fenêtre Chrome)
# Ouvrir une nouvelle fenêtre incognito : http://localhost:PORT
```

---

**C'est tout ! Simple, non ?** 🚀

Le but de ce POC est de prouver que :
1. ✅ On peut capturer la caméra du patient
2. ✅ On peut transmettre le flux via WebRTC
3. ✅ On peut afficher le flux chez le praticien
4. ✅ Ça passe par notre serveur (signalisation)

**Mission accomplie si ça marche !** 🎉
