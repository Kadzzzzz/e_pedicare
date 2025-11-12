import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

/// Service de gestion des connexions et streaming vidéo via LiveKit
/// Gère la connexion au serveur, l'envoi et la réception de flux vidéo
class LiveKitService extends ChangeNotifier {
  // Instance singleton
  static final LiveKitService _instance = LiveKitService._internal();
  factory LiveKitService() => _instance;
  LiveKitService._internal();

  // Room LiveKit (salle de conférence)
  Room? _room;
  Room? get room => _room;

  // État de la connexion
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // Caméra et microphone locaux
  LocalVideoTrack? _localVideoTrack;
  LocalAudioTrack? _localAudioTrack;

  LocalVideoTrack? get localVideoTrack => _localVideoTrack;
  LocalAudioTrack? get localAudioTrack => _localAudioTrack;

  // Participants distants (le praticien verra les parents, et vice versa)
  Map<String, RemoteParticipant> _remoteParticipants = {};
  Map<String, RemoteParticipant> get remoteParticipants => _remoteParticipants;

  // Position actuelle de la caméra
  CameraPosition _currentCameraPosition = CameraPosition.front;

  /// Se connecter à une room LiveKit
  ///
  /// [url] : URL du serveur LiveKit (ex: wss://your-livekit-server.com)
  /// [token] : Token JWT généré par le backend
  /// [enableCamera] : Activer la caméra locale (true pour client, false pour praticien)
  /// [enableMicrophone] : Activer le micro local
  Future<void> connect({
    required String url,
    required String token,
    bool enableCamera = true,
    bool enableMicrophone = true,
  }) async {
    try {
      // Créer la room
      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      // Écouter les événements de la room
      _setupRoomListeners();

      // Se connecter au serveur LiveKit
      await _room!.connect(
        url,
        token,
        connectOptions: const ConnectOptions(
          autoSubscribe: true,
        ),
      );

      // Publier les flux locaux si demandé
      if (enableCamera || enableMicrophone) {
        await _publishLocalTracks(
          enableCamera: enableCamera,
          enableMicrophone: enableMicrophone,
        );
      }

      _isConnected = true;
      notifyListeners();

      debugPrint('✅ Connecté à LiveKit: ${_room?.name}');
    } catch (e) {
      debugPrint('❌ Erreur de connexion LiveKit: $e');
      rethrow;
    }
  }

  /// Publier les flux audio/vidéo locaux
  Future<void> _publishLocalTracks({
    required bool enableCamera,
    required bool enableMicrophone,
  }) async {
    if (_room == null) return;

    try {
      // Créer et publier le flux vidéo
      if (enableCamera) {
        _localVideoTrack = await LocalVideoTrack.createCameraTrack(
          CameraCaptureOptions(
            cameraPosition: _currentCameraPosition,
            params: VideoParametersPresets.h720_169,
          ),
        );
        await _room!.localParticipant?.publishVideoTrack(_localVideoTrack!);
        debugPrint('📹 Flux vidéo publié');
      }

      // Créer et publier le flux audio
      if (enableMicrophone) {
        _localAudioTrack = await LocalAudioTrack.create();
        await _room!.localParticipant?.publishAudioTrack(_localAudioTrack!);
        debugPrint('🎤 Flux audio publié');
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur publication des tracks: $e');
      rethrow;
    }
  }

  /// Configurer les écouteurs d'événements de la room
  void _setupRoomListeners() {
    if (_room == null) return;

    _room!.addListener(() {
      final participants = _room!.remoteParticipants;
      _remoteParticipants = {
        for (var p in participants.values) p.sid: p
      };
      notifyListeners();
      debugPrint('👥 Participants: ${participants.length}');
    });
  }

  /// Basculer la caméra (avant/arrière)
  Future<void> switchCamera() async {
    if (_localVideoTrack == null || _room == null) return;

    try {
      // Déterminer la nouvelle position
      _currentCameraPosition = _currentCameraPosition == CameraPosition.front
          ? CameraPosition.back
          : CameraPosition.front;

      // Arrêter l'ancien track
      await _localVideoTrack!.stop();
      // Note: unpublishTrack n'est plus nécessaire avec la version 2.5.3

      // Créer un nouveau track avec la nouvelle caméra
      _localVideoTrack = await LocalVideoTrack.createCameraTrack(
        CameraCaptureOptions(
          cameraPosition: _currentCameraPosition,
          params: VideoParametersPresets.h720_169,
        ),
      );

      // Publier le nouveau track
      await _room!.localParticipant?.publishVideoTrack(_localVideoTrack!);

      notifyListeners();
      debugPrint('📷 Caméra basculée: $_currentCameraPosition');
    } catch (e) {
      debugPrint('❌ Erreur basculement caméra: $e');
    }
  }

  /// Activer/désactiver la caméra
  Future<void> toggleCamera() async {
    if (_localVideoTrack == null) return;

    try {
      if (_localVideoTrack!.muted) {
        await _localVideoTrack!.unmute();
        debugPrint('📹 Caméra: ON');
      } else {
        await _localVideoTrack!.mute();
        debugPrint('📹 Caméra: OFF');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur toggle caméra: $e');
    }
  }

  /// Activer/désactiver le micro
  Future<void> toggleMicrophone() async {
    if (_localAudioTrack == null) return;

    try {
      if (_localAudioTrack!.muted) {
        await _localAudioTrack!.unmute();
        debugPrint('🎤 Micro: ON');
      } else {
        await _localAudioTrack!.mute();
        debugPrint('🎤 Micro: OFF');
      }
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Erreur toggle micro: $e');
    }
  }

  /// Vérifier si la caméra est activée
  bool get isCameraEnabled => _localVideoTrack != null && !_localVideoTrack!.muted;

  /// Vérifier si le micro est activé
  bool get isMicrophoneEnabled => _localAudioTrack != null && !_localAudioTrack!.muted;

  /// Obtenir le flux vidéo d'un participant distant
  /// Utile pour afficher la vidéo du client côté praticien
  VideoTrack? getRemoteVideoTrack(String participantSid) {
    final participant = _remoteParticipants[participantSid];
    if (participant == null) return null;

    // Chercher le premier track vidéo publié
    for (var track in participant.videoTrackPublications) {
      if (track.track != null && track.subscribed) {
        return track.track as VideoTrack;
      }
    }
    return null;
  }

  /// Obtenir tous les flux vidéo distants
  List<VideoTrack> getAllRemoteVideoTracks() {
    List<VideoTrack> tracks = [];
    for (var participant in _remoteParticipants.values) {
      for (var track in participant.videoTrackPublications) {
        if (track.track != null && track.subscribed) {
          tracks.add(track.track as VideoTrack);
        }
      }
    }
    return tracks;
  }

  /// Se déconnecter et nettoyer les ressources
  Future<void> disconnect() async {
    try {
      // Arrêter les tracks locaux
      await _localVideoTrack?.stop();
      await _localAudioTrack?.stop();

      // Déconnecter la room
      await _room?.disconnect();
      await _room?.dispose();

      // Nettoyer les références
      _room = null;
      _localVideoTrack = null;
      _localAudioTrack = null;
      _remoteParticipants.clear();
      _isConnected = false;

      notifyListeners();
      debugPrint('👋 Déconnecté de LiveKit');
    } catch (e) {
      debugPrint('❌ Erreur déconnexion: $e');
    }
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
