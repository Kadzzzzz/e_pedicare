# POC - Streaming Vidéo en Temps Réel (e-PediCare)

## 📌 Vue d'ensemble

Ce POC (Proof of Concept) implémente le cœur de l'application e-PediCare : un système de streaming vidéo en temps réel entre les parents/enfants et les praticiens médicaux.

### Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  Client/Parent  │         │  Serveur LiveKit │         │   Praticien     │
│                 │         │                  │         │                 │
│  📹 Caméra ─────┼────────▶│  Serveur SFU     │────────▶│  📺 Écran       │
│  🎤 Micro       │  WebRTC │  + Enregistrement│  WebRTC │                 │
└─────────────────┘         └──────────────────┘         └─────────────────┘
         │                           │                            │
         │                           │                            │
         └───────────── Flask Backend (Tokens JWT) ──────────────┘
```

### Technologies utilisées

- **Frontend** : Flutter + LiveKit Client SDK
- **Backend** : Flask + LiveKit API (génération de tokens)
- **Streaming** : LiveKit (WebRTC SFU)
- **Authentification** : JWT (Flask-JWT-Extended)

---

## 🚀 Installation et Configuration

### Étape 1 : Configuration LiveKit Cloud (Gratuit)

1. **Créer un compte LiveKit gratuit** :
   - Allez sur https://livekit.io/cloud
   - Cliquez sur "Sign up" et créez votre compte
   - Validez votre email

2. **Créer un projet** :
   - Dans le dashboard, cliquez sur "New Project"
   - Donnez un nom à votre projet (ex: "epedicare-poc")

3. **Récupérer les clés API** :
   - Dans votre projet, allez dans "Settings" > "Keys"
   - Copiez les 3 informations suivantes :
     - **LiveKit URL** : `wss://your-project-xxxxx.livekit.cloud`
     - **API Key** : `APIxxxxxxxxx`
     - **API Secret** : `secretxxxxxxxxxxxxxxxxxx`

### Étape 2 : Configuration du Backend

1. **Installer les dépendances Python** :
   ```bash
   cd backend
   pip install -r requirements.txt
   ```

2. **Créer le fichier `.env`** :
   ```bash
   cp .env.example .env
   ```

3. **Éditer le fichier `.env`** avec vos clés LiveKit :
   ```env
   # LiveKit Configuration
   LIVEKIT_URL=wss://your-project-xxxxx.livekit.cloud
   LIVEKIT_API_KEY=APIxxxxxxxxx
   LIVEKIT_API_SECRET=secretxxxxxxxxxxxxxxxxxx

   # Flask
   JWT_SECRET_KEY=votre-cle-secrete-unique-a-changer
   DATABASE_URI=sqlite:///database/epedicare.db
   ```

4. **Lancer le serveur Flask** :
   ```bash
   python app.py
   ```

   Le serveur démarre sur `http://localhost:5000`

### Étape 3 : Configuration du Frontend Flutter

1. **Installer les dépendances Flutter** :
   ```bash
   cd frontend
   flutter pub get
   ```

2. **Configurer l'URL du backend** :

   Éditez `frontend/lib/services/api_service.dart` ligne 11 :
   ```dart
   static const String baseUrl = 'http://localhost:5000/api';
   ```

   Si vous testez sur mobile, remplacez `localhost` par l'IP de votre ordinateur :
   ```dart
   static const String baseUrl = 'http://192.168.1.X:5000/api';
   ```

3. **Lancer l'application Flutter** :
   ```bash
   # Pour le web
   flutter run -d chrome

   # Pour Android
   flutter run -d android

   # Pour iOS (Mac uniquement)
   flutter run -d ios
   ```

---

## 🎯 Utilisation du POC

### Scénario 1 : Test sur un seul appareil

1. **Démarrer le backend Flask**
   ```bash
   cd backend && python app.py
   ```

2. **Ouvrir 2 fenêtres de l'application** :
   - Fenêtre 1 : Client (parent)
   - Fenêtre 2 : Praticien

3. **Côté Client (Fenêtre 1)** :
   - Cliquez sur "Client" dans la barre de navigation
   - Entrez un nom de session : `test-session-1`
   - Cliquez sur "Démarrer la session"
   - Autorisez l'accès à la caméra et au micro
   - Vous devriez voir votre flux vidéo

4. **Côté Praticien (Fenêtre 2)** :
   - Cliquez sur "Praticien" dans la barre de navigation
   - Entrez le même nom de session : `test-session-1`
   - Cliquez sur "Rejoindre la session"
   - Vous devriez voir le flux vidéo du client

### Scénario 2 : Test sur deux appareils

1. **Appareil 1 (Client - ex: smartphone)** :
   - Lancez l'app Flutter
   - Allez sur la page "Client"
   - Créez une session : `session-enfant-alice`
   - Démarrez le streaming

2. **Appareil 2 (Praticien - ex: ordinateur)** :
   - Lancez l'app Flutter (ou ouvrez dans le navigateur)
   - Allez sur la page "Praticien"
   - Rejoignez la session : `session-enfant-alice`
   - Visualisez le flux en temps réel

---

## 🔧 Contrôles disponibles

### Page Client (Parent)
- ✅ **Démarrer/Terminer** une session
- 📹 **Activer/Désactiver** la caméra
- 🎤 **Activer/Désactiver** le microphone
- 🔄 **Basculer** entre caméra avant/arrière
- 📺 **Prévisualisation** du flux local

### Page Praticien
- ✅ **Rejoindre** une session existante
- 📺 **Visualiser** le flux vidéo du client en temps réel
- 👥 **Voir** le nombre de participants
- 🚪 **Quitter** la session

---

## 📊 API Endpoints Backend

### Authentification (JWT requis pour /video/*)

#### `POST /api/video/create-session`
Créer une nouvelle session vidéo

**Body** :
```json
{
  "room_name": "session-enfant-123",
  "child_id": "optional-child-id"
}
```

**Response** :
```json
{
  "session_id": "session-enfant-123-1234567890.123",
  "room_name": "session-enfant-123",
  "livekit_url": "wss://your-project.livekit.cloud",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "message": "Session créée avec succès"
}
```

#### `POST /api/video/join-session`
Rejoindre une session existante

**Body** :
```json
{
  "room_name": "session-enfant-123",
  "participant_name": "Dr. Martin"
}
```

**Response** :
```json
{
  "room_name": "session-enfant-123",
  "livekit_url": "wss://your-project.livekit.cloud",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "participant_name": "Dr. Martin",
  "message": "Token généré avec succès"
}
```

#### `POST /api/video/token/generate` (Sans authentification - POC uniquement)
Générer un token simple pour tests

**Body** :
```json
{
  "room_name": "test-room",
  "participant_name": "Test User",
  "identity": "user-123"
}
```

---

## 🛠️ Structure du Code

### Frontend Flutter

```
frontend/lib/
├── services/
│   ├── livekit_service.dart     # Gestion LiveKit (connexion, streaming)
│   └── api_service.dart         # Communication avec le backend Flask
├── pages/
│   ├── client_page.dart         # Interface Client/Parent
│   └── praticien_page.dart      # Interface Praticien
└── widgets/
    └── app_bar.dart             # Barre de navigation
```

### Backend Flask

```
backend/
├── routes/
│   └── video.py                 # Routes API pour le streaming vidéo
├── config.py                    # Configuration (LiveKit, JWT, DB)
└── app.py                       # Point d'entrée Flask
```

---

## 🎓 Fonctionnement Technique

### 1. Création d'une session (Client)

```
Client App                  Flask Backend              LiveKit Server
    │                            │                           │
    ├─── POST /video/create ────▶│                           │
    │    {room_name}             │                           │
    │                            ├─── Generate JWT Token ───▶│
    │                            │    (API Key + Secret)     │
    │◀── Token + URL ────────────┤                           │
    │                            │                           │
    ├─── Connect to LiveKit ─────────────────────────────────▶│
    │    (WebRTC)                │                           │
    ├─── Publish Video/Audio ────────────────────────────────▶│
    │                            │                           │
```

### 2. Rejoindre une session (Praticien)

```
Praticien App               Flask Backend              LiveKit Server
    │                            │                           │
    ├─── POST /video/join ──────▶│                           │
    │    {room_name}             │                           │
    │                            ├─── Generate JWT Token ───▶│
    │                            │    (API Key + Secret)     │
    │◀── Token + URL ────────────┤                           │
    │                            │                           │
    ├─── Connect to LiveKit ─────────────────────────────────▶│
    │    (WebRTC)                │                           │
    │◀── Receive Video/Audio ─────────────────────────────────┤
    │                            │                           │
```

### 3. Flux WebRTC via Serveur (SFU)

LiveKit utilise une architecture **SFU (Selective Forwarding Unit)** :
- Le client envoie **1 flux** au serveur
- Le serveur relaie ce flux au(x) praticien(s)
- **Avantages** :
  - Bande passante optimisée côté client
  - Scalabilité (plusieurs praticiens peuvent rejoindre)
  - Enregistrement centralisé possible
  - Latence ultra-faible (<100ms)

---

## ⚠️ Limitations du POC

Ce POC se concentre sur le streaming vidéo. **Non implémenté** :
- ❌ Authentification utilisateur complète
- ❌ Gestion des rôles (parent/expert)
- ❌ Envoi de stimuli visuels (prévu pour étape 2)
- ❌ Enregistrement des sessions sur CDN
- ❌ Superposition des flux vidéo et stimuli
- ❌ Gestion de la base de données des sessions
- ❌ Interface d'administration

---

## 🔐 Sécurité

### Pour le POC (Acceptable)
- Tokens JWT avec expiration (6 heures)
- CORS activé pour développement
- Route `/video/token/generate` sans auth (tests uniquement)

### Pour la Production (À implémenter)
- ⚠️ **SUPPRIMER** la route `/video/token/generate` non sécurisée
- ⚠️ Authentification obligatoire sur toutes les routes /video
- ⚠️ HTTPS obligatoire (TLS)
- ⚠️ Validation stricte des rôles (parent vs praticien)
- ⚠️ Limitation du débit (rate limiting)
- ⚠️ Chiffrement end-to-end (E2EE) si requis
- ⚠️ Conformité RGPD pour les données médicales

---

## 🐛 Dépannage

### Problème : "Erreur de connexion au backend"
**Solution** :
- Vérifiez que Flask tourne sur `http://localhost:5000`
- Sur mobile, utilisez l'IP locale (pas localhost)
- Désactivez temporairement le pare-feu

### Problème : "Accès caméra refusé"
**Solution** :
- Autorisez les permissions caméra/micro dans le navigateur
- Sur Android : vérifiez `AndroidManifest.xml` (permissions déjà ajoutées)
- Sur iOS : ajoutez les clés dans `Info.plist` (si non fait)

### Problème : "Token invalide" ou "LiveKit connection failed"
**Solution** :
- Vérifiez vos clés LiveKit dans `.env`
- Vérifiez que `LIVEKIT_URL` commence par `wss://` (pas `https://`)
- Testez vos clés sur le dashboard LiveKit

### Problème : "No remote video tracks"
**Solution** :
- Assurez-vous que le client a démarré **avant** le praticien
- Vérifiez que la caméra du client est activée (bouton bleu)
- Attendez quelques secondes (délai de propagation WebRTC)

---

## 📈 Prochaines Étapes (Post-POC)

### Étape 2 : Stimuli visuels
- Envoi de formes/couleurs/sons du praticien vers le client
- Superposition des stimuli sur la vidéo
- Enregistrement synchronisé (vidéo + stimuli + timestamps)

### Étape 3 : Enregistrement sur CDN
- Intégration avec AWS S3 / Azure Blob Storage
- Compression vidéo optimale (H.264/H.265)
- Métadonnées de session (durée, participants, stimuli)

### Étape 4 : Analytics et Diagnostic
- Détection automatique des réactions de l'enfant
- Analyse vidéo par IA (optionnel)
- Génération de rapports pour les praticiens

---

## 📞 Support

Pour toute question technique sur ce POC :
- Vérifiez d'abord ce README
- Consultez la documentation LiveKit : https://docs.livekit.io
- Vérifiez les logs Flask (terminal backend)
- Vérifiez les logs Flutter (terminal frontend ou DevTools)

---

**POC développé pour e-PediCare - Streaming Vidéo Temps Réel**
