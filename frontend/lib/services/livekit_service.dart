import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

// Définissez ici l'URL de votre serveur LiveKit
// Utilisez une URL de test LiveKit (ex: 'ws://localhost:7880' si vous l'hébergez localement)
const String livekitUrl = 'wss://meet.livekit.io'; 

class LiveKitService extends ChangeNotifier {
  Room? _room;
  String? _error;
  
  // Le widget pour afficher la vidéo du pair distant
  VideoTrack? remoteTrack;

  // --- Propriétés de la Salle ---
  Room? get room => _room;
  String? get error => _error;

  // Méthode pour rejoindre une salle
  Future<void> joinRoom(String token) async {
    _error = null;
    try {
      // 1. Créer une nouvelle salle
      _room = Room();

      // 2. Définir le gestionnaire d'événements
      _room!.addListener(_onRoomEvent);

      // 3. Connecter à la salle
      await _room!.connect(
        livekitUrl,
        token,
        fastConnect: true,
      );
      print('✅ LiveKit connecté !');
      notifyListeners();

    } catch (e) {
      _error = 'Erreur de connexion LiveKit: $e';
      print(_error);
      notifyListeners();
    }
  }

  // Gère les événements dans la salle (quand d'autres participants se connectent, publient)
  void _onRoomEvent(RoomEvent event) {
    if (event is RoomConnectEvent) {
      print('Salle connectée');
    } else if (event is TrackSubscribedEvent) {
      // Quelqu'un (le Client ou le Praticien) a publié une vidéo, nous devons la montrer !
      if (event.participant is RemoteParticipant && event.track is VideoTrack) {
        remoteTrack = event.track as VideoTrack;
        print('Vidéo distante souscrite !');
        notifyListeners();
      }
    } else if (event is ParticipantConnectedEvent) {
      print('Nouveau participant: ${event.participant.identity}');
    }
    // ... d'autres événements de gestion d'erreurs, etc.
  }

  // Publie la piste vidéo locale du participant
  Future<void> publishLocalVideo() async {
      await _room!.localParticipant?.setCameraEnabled(true);
      print('Vidéo locale publiée.');
  }
  
  // Méthode pour quitter la salle
  Future<void> disconnect() async {
    await _room?.disconnect();
    _room = null;
    remoteTrack = null;
    notifyListeners();
  }
}