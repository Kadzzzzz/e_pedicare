// lib/services/livekit_service.dart
// VERSION COMPATIBLE livekit_client 2.5.3

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';

// --- CONFIGURATION ---

// 🌐 Web/Desktop (Chrome, Edge, etc.)
const String tokenServerUrl = 'http://localhost:5000/api/token';

// 🤖 Émulateur Android (par défaut)
// const String tokenServerUrl = 'http://10.0.2.2:5000/api/token';

// 🍎 Simulateur iOS - Décommenter si besoin
// const String tokenServerUrl = 'http://localhost:5000/api/token';

// 📱 Appareil Physique - Remplacer X.X.X.X par votre IP
// const String tokenServerUrl = 'http://X.X.X.X:5000/api/token';

class LiveKitService extends ChangeNotifier {
  Room? _room;
  String? _error;
  VideoTrack? _localTrack;
  VideoTrack? _remoteTrack;
  bool _isConnecting = false;
  String? _livekitUrl;

  Room? get room => _room;
  String? get error => _error;
  VideoTrack? get localTrack => _localTrack;
  VideoTrack? get remoteTrack => _remoteTrack;
  bool get isConnecting => _isConnecting;

  LiveKitService() {
    if (kDebugMode) {
      print('🔧 LiveKitService: Init (v2.5.3 compatible)');
      print('🔧 Token Server: $tokenServerUrl');
    }
  }

  void _log(String msg) {
    if (kDebugMode) print('🔵 LiveKit: $msg');
  }

  void _logError(String msg) {
    if (kDebugMode) print('🔴 LiveKit Error: $msg');
  }

  Future<Map<String, String>?> _fetchTokenAndUrl(String identity) async {
    _log('Demande token pour: $identity');

    try {
      final response = await http
          .post(
        Uri.parse(tokenServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identity': identity}),
      )
          .timeout(const Duration(seconds: 10));

      _log('Réponse Flask: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'] as String?;
        final url = data['url'] as String?;

        if (token == null || token.isEmpty) {
          throw Exception('Token vide');
        }
        if (url == null || url.isEmpty) {
          throw Exception('URL manquante');
        }

        _log('✅ Token reçu (${token.length} chars)');
        _log('✅ URL: $url');

        return {'token': token, 'url': url};
      } else {
        throw Exception('Erreur serveur: ${response.statusCode}');
      }
    } catch (e) {
      _logError('Erreur: $e');
      rethrow;
    }
  }

  Future<void> joinRoom(String identity) async {
    if (_isConnecting) {
      _log('⚠️ Connexion en cours...');
      return;
    }

    if (_room != null) {
      _log('⚠️ Déjà connecté');
      return;
    }

    _isConnecting = true;
    _error = null;
    notifyListeners();

    try {
      _log('📡 Récupération token...');
      final credentials = await _fetchTokenAndUrl(identity);

      if (credentials == null) throw Exception('Credentials null');

      final token = credentials['token']!;
      _livekitUrl = credentials['url']!;

      _log('🏠 Création Room...');
      _room = Room(
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultCameraCaptureOptions: CameraCaptureOptions(
            maxFrameRate: 30,
          ),
        ),
      );

      _log('👂 Configuration listeners...');
      _room!.addListener(_onRoomDidUpdate);

      _log('🔗 Connexion à $_livekitUrl...');
      await _room!.connect(_livekitUrl!, token);

      _log('✅ Connecté: $identity');
      _isConnecting = false;
      notifyListeners();

    } catch (e) {
      _logError('Échec: $e');
      _error = 'Erreur: $e';
      _isConnecting = false;

      if (_room != null) {
        await _room!.dispose();
        _room = null;
      }

      notifyListeners();
    }
  }

  void _onRoomDidUpdate() {
    if (_room == null) return;

    bool hasChanges = false;

    // Vidéo locale
    final localParticipant = _room!.localParticipant;
    if (localParticipant != null) {
      VideoTrack? newLocalTrack;

      for (var pub in localParticipant.videoTrackPublications) {
        if (pub.track != null) {
          newLocalTrack = pub.track as VideoTrack;
          break;
        }
      }

      if (newLocalTrack != _localTrack) {
        _localTrack = newLocalTrack;
        _log('🎥 Local: ${_localTrack != null ? "Active" : "Inactive"}');
        hasChanges = true;
      }
    }

    // Vidéo distante
    final remoteParticipants = _room!.remoteParticipants.values.toList();
    VideoTrack? newRemoteTrack;

    for (var participant in remoteParticipants) {
      for (var pub in participant.videoTrackPublications) {
        if (pub.subscribed && pub.track != null) {
          newRemoteTrack = pub.track as VideoTrack;
          _log('📺 Distant: ${participant.identity}');
          break;
        }
      }
      if (newRemoteTrack != null) break;
    }

    if (newRemoteTrack != _remoteTrack) {
      _remoteTrack = newRemoteTrack;
      _log('🎥 Remote: ${_remoteTrack != null ? "Active" : "Inactive"}');
      hasChanges = true;
    }

    if (hasChanges) notifyListeners();
  }

  Future<void> publishLocalVideo() async {
    if (_room == null || _room!.localParticipant == null) {
      _logError('Pas de participant local');
      _error = 'Pas de participant local';
      notifyListeners();
      return;
    }

    try {
      _log('📹 Activation caméra...');
      await _room!.localParticipant!.setCameraEnabled(true);
      _log('✅ Caméra activée');

      await Future.delayed(const Duration(milliseconds: 500));
      _onRoomDidUpdate();
    } catch (e) {
      _logError('Erreur caméra: $e');
      _error = 'Erreur caméra: $e';
      notifyListeners();
    }
  }

  Future<void> unpublishLocalVideo() async {
    if (_room == null || _room!.localParticipant == null) return;

    try {
      _log('🔇 Désactivation caméra...');
      await _room!.localParticipant!.setCameraEnabled(false);
      _log('✅ Caméra désactivée');
      _onRoomDidUpdate();
    } catch (e) {
      _logError('Erreur: $e');
    }
  }

  Future<void> disconnect() async {
    _log('🔌 Déconnexion...');

    if (_room != null) {
      _room!.removeListener(_onRoomDidUpdate);
      await _room!.disconnect();
      await _room!.dispose();
      _room = null;
    }

    _localTrack = null;
    _remoteTrack = null;
    _error = null;
    _isConnecting = false;
    _livekitUrl = null;

    _log('✅ Déconnecté');
    notifyListeners();
  }

  @override
  void dispose() {
    _log('🧹 Nettoyage...');
    disconnect();
    super.dispose();
  }

  String getConnectionStatus() {
    if (_isConnecting) return 'Connexion...';
    if (_room == null) return 'Déconnecté';

    switch (_room!.connectionState) {
      case ConnectionState.disconnected:
        return 'Déconnecté';
      case ConnectionState.connecting:
        return 'Connexion...';
      case ConnectionState.connected:
        return 'Connecté';
      case ConnectionState.reconnecting:
        return 'Reconnexion...';
      default:
        return 'Inconnu';
    }
  }

  Map<String, dynamic> getDiagnostics() {
    return {
      'isConnecting': _isConnecting,
      'hasRoom': _room != null,
      'connectionState': _room?.connectionState.toString() ?? 'null',
      'localTrackActive': _localTrack != null,
      'remoteTrackActive': _remoteTrack != null,
      'error': _error,
      'localParticipant': _room?.localParticipant?.identity ?? 'null',
      'remoteParticipants': _room?.remoteParticipants.length ?? 0,
      'livekitUrl': _livekitUrl ?? 'non récupérée',
    };
  }
}