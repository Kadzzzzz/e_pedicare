// lib/services/livekit_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';

// --- CONFIGURATION DE L'INFRASTRUCTURE ---
// LiveKit Server (Port 7880 par défaut, via machine hôte)
const String livekitUrl = 'ws://10.0.2.2:7880'; 
// Flask Token Server (Port 5000)
const String tokenServerUrl = 'http://10.0.2.2:5000/api/token'; 

class LiveKitService extends ChangeNotifier {
  // Propriétés (privées)
  Room? _room;
  String? _error;
  VideoTrack? localTrack;
  VideoTrack? remoteTrack;

  // Accesseurs (publics)
  Room? get room => _room;
  String? get error => _error;
  
  // Constructeur simple
  LiveKitService();

  // --- 1. RÉCUPÉRATION DU TOKEN ET CONNEXION À LIVEKIT ---
  Future<void> joinRoom(String identity) async {
    _error = null;
    String? token;

    // A. Récupération du Token depuis Flask
    try {
      final response = await http.post(
        Uri.parse(tokenServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identity': identity}),
      );

      if (response.statusCode == 200) {
        token = jsonDecode(response.body)['token'];
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception('Échec du token (Code ${response.statusCode}): ${errorData['error']}');
      }
    } catch (e) {
      _error = 'Erreur Flask/Token: $e';
      notifyListeners();
      return;
    }

    // B. Connexion à la salle LiveKit avec le token
    try {
      _room = Room();
      
      // 🔧 Configuration de l'écoute des événements AVANT la connexion
      _room!.addListener(_onRoomDidUpdate);
      
      // 🔧 Connexion avec les options de capture
      await _room!.connect(
        livekitUrl, 
        token!,
        roomOptions: const RoomOptions(
        defaultCameraCaptureOptions: CameraCaptureOptions(
            maxFrameRate: 30, 
          ),
        ),
      );
      
      notifyListeners();
      print('✅ LiveKit connecté en tant que $identity');

    } catch (e) {
      _error = 'Erreur de connexion LiveKit: $e';
      _room?.dispose();
      _room = null;
      notifyListeners();
    }
  }

  // --- 2. GESTION DES ÉVÉNEMENTS DANS LA SALLE ---
  void _onRoomDidUpdate() {
    // 🔧 Récupération des tracks depuis les participants
    
    // Vidéo locale
    final localVideoTrack = _room?.localParticipant?.videoTrackPublications
        .where((pub) => pub.track != null)
        .map((pub) => pub.track as VideoTrack)
        .firstOrNull;
    
    if (localVideoTrack != localTrack) {
      localTrack = localVideoTrack;
      print('Vidéo locale mise à jour');
      notifyListeners();
    }

    // Vidéo distante (premier participant distant trouvé)
    final remoteParticipants = _room?.remoteParticipants.values.toList() ?? [];
    VideoTrack? newRemoteTrack;
    
    for (var participant in remoteParticipants) {
      final videoTrack = participant.videoTrackPublications
          .where((pub) => pub.subscribed && pub.track != null)
          .map((pub) => pub.track as VideoTrack)
          .firstOrNull;
      
      if (videoTrack != null) {
        newRemoteTrack = videoTrack;
        break;
      }
    }
    
    if (newRemoteTrack != remoteTrack) {
      remoteTrack = newRemoteTrack;
      print('Vidéo distante mise à jour');
      notifyListeners();
    }
  }

  // --- 3. PUBLICATION VIDÉO ---
  Future<void> publishLocalVideo() async {
    if (_room?.localParticipant == null) {
      print('⚠️ Pas de participant local');
      return;
    }
    
    try {
      await _room!.localParticipant!.setCameraEnabled(true);
      print('📹 Caméra activée');
    } catch (e) {
      print('❌ Erreur activation caméra: $e');
      _error = 'Erreur activation caméra: $e';
      notifyListeners();
    }
  }

  // --- 4. DÉCONNEXION ---
  Future<void> disconnect() async {
    _room?.removeListener(_onRoomDidUpdate);
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
    localTrack = null;
    remoteTrack = null;
    notifyListeners();
  }

  // 🔧 Nettoyage lors de la destruction du service
  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}