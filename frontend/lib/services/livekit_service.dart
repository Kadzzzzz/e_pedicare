// lib/services/livekit_service.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';

// 🚨 URL du serveur LiveKit (défini dans main.dart)
const String livekitUrl = 'ws://10.0.2.2:7880'; 
// 🚨 URL du serveur Flask pour les tokens
const String tokenServerUrl = 'http://10.0.2.2:5000/api/token'; 

class LiveKitService extends ChangeNotifier {
  Room? _room;
  String? _error;
  
  // Pistes vidéo gérées par le service
  VideoTrack? localTrack; // Piste vidéo publiée par cet utilisateur
  VideoTrack? remoteTrack; // Piste vidéo reçue du pair (le Client ou le Praticien)

  Room? get room => _room;
  String? get error => _error;

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
        throw Exception('Échec de la récupération du token : ${jsonDecode(response.body)['error']}');
      }
    } catch (e) {
      _error = 'Erreur Flask/Token: $e';
      notifyListeners();
      return;
    }

    // B. Connexion à la salle LiveKit
    try {
      _room = Room(
        // Configuration minimale pour la connexion
        options: const RoomOptions(
          defaultCameraCaptureOptions: CameraCaptureOptions(
            resolution: VideoDimensions(width: 640, height: 480),
            cameraPosition: CameraPosition.front, // Utilise la caméra frontale par défaut
          ),
        ),
      );
      _room!.addListener(_onRoomEvent);
      
      await _room!.connect(livekitUrl, token!, fastConnect: true);
      
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
  void _onRoomEvent(RoomEvent event) {
    if (event is TrackSubscribedEvent) {
      // Un participant distant a publié une piste (la vidéo du Client ou du Praticien)
      if (event.participant is RemoteParticipant && event.track is VideoTrack) {
        remoteTrack = event.track as VideoTrack;
        print('Vidéo distante souscrite !');
        notifyListeners();
      }
    } 
    // Quand l'utilisateur publie sa propre piste locale
    else if (event is LocalTrackPublishedEvent) {
      if (event.track is VideoTrack) {
        localTrack = event.track as VideoTrack;
        print('Vidéo locale publiée.');
        notifyListeners();
      }
    }
    // Gérer la déconnexion, etc.
    else if (event is RoomDisconnectedEvent || event is ParticipantDisconnectedEvent) {
      print('Déconnexion détectée.');
      remoteTrack = null;
      localTrack = null;
      notifyListeners();
    }
  }

  // --- 3. PUBLICATION VIDÉO ---
  Future<void> publishLocalVideo() async {
      await _room!.localParticipant?.setCameraEnabled(true);
  }
  
  // --- 4. DÉCONNEXION ---
  Future<void> disconnect() async {
    await _room?.disconnect();
    _room = null;
    localTrack = null;
    remoteTrack = null;
    notifyListeners();
  }
}