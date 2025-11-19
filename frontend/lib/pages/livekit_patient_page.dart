import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Page Patient avec LiveKit - Ultra simple
/// Le flux vidéo passe par le serveur LiveKit (pas de P2P)
/// Permet l'enregistrement et le traitement côté serveur
class LiveKitPatientPage extends StatefulWidget {
  const LiveKitPatientPage({super.key});

  @override
  State<LiveKitPatientPage> createState() => _LiveKitPatientPageState();
}

class _LiveKitPatientPageState extends State<LiveKitPatientPage> {
  // Contrôles UI
  final TextEditingController _sessionController = TextEditingController();
  bool _isConnected = false;
  String _status = 'Non connecté';

  // LiveKit
  Room? _room;
  LocalVideoTrack? _localVideoTrack;
  LocalAudioTrack? _localAudioTrack;

  @override
  void dispose() {
    _disconnect();
    _sessionController.dispose();
    super.dispose();
  }

  /// Démarrer la session patient
  Future<void> _startSession() async {
    final sessionId = _sessionController.text.trim();
    if (sessionId.isEmpty) {
      _setStatus('❌ Entrez un ID de session');
      return;
    }

    _setStatus('🔑 Demande de token...');

    try {
      // 1. Obtenir un token du serveur Flask
      final tokenData = await _getToken(sessionId, 'patient');

      _setStatus('🎥 Initialisation de la caméra...');

      // 2. Créer la room LiveKit
      _room = await LiveKitClient.connect(
        tokenData['url'],
        tokenData['token'],
        roomOptions: const RoomOptions(
          defaultCameraCaptureOptions: CameraCaptureOptions(
            maxFrameRate: 30,
            params: VideoParametersPresets.h720_169,
          ),
          defaultAudioPublishOptions: AudioPublishOptions(
            name: 'patient-audio',
          ),
          defaultVideoPublishOptions: VideoPublishOptions(
            name: 'patient-video',
          ),
        ),
      );

      _setStatus('📹 Activation de la caméra...');

      // 3. Activer la caméra et le micro
      await _room!.localParticipant?.setCameraEnabled(true);
      await _room!.localParticipant?.setMicrophoneEnabled(true);

      // 4. Récupérer les tracks locaux pour l'aperçu
      _localVideoTrack = _room!.localParticipant?.videoTrackPublications.firstOrNull?.track as LocalVideoTrack?;
      _localAudioTrack = _room!.localParticipant?.audioTrackPublications.firstOrNull?.track as LocalAudioTrack?;

      setState(() {
        _isConnected = true;
      });

      _setStatus('✅ Connecté - En attente du praticien...');

      // 5. Écouter les événements
      _room!.addListener(_onRoomUpdate);

      print('✅ Patient connecté à la room: $sessionId');

    } catch (e) {
      _setStatus('❌ Erreur: $e');
      print('❌ Erreur connexion: $e');
    }
  }

  /// Obtenir un token depuis le serveur Flask
  Future<Map<String, dynamic>> _getToken(String roomName, String role) async {
    final response = await http.post(
      Uri.parse('http://localhost:5002/token'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'room_name': roomName,
        'participant_name': role,
        'role': role,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur serveur: ${response.statusCode}');
    }
  }

  /// Écouter les changements de la room
  void _onRoomUpdate() {
    // Vérifier si un praticien a rejoint
    final participants = _room?.remoteParticipants.values.toList() ?? [];
    if (participants.isNotEmpty) {
      _setStatus('👨‍⚕️ Praticien connecté - Streaming en cours...');
    }
  }

  /// Déconnexion
  Future<void> _disconnect() async {
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
    _localVideoTrack = null;
    _localAudioTrack = null;
  }

  void _setStatus(String status) {
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📱 Patient - LiveKit POC'),
        backgroundColor: Colors.blue,
        actions: [
          if (_isConnected)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                _disconnect();
                setState(() {
                  _isConnected = false;
                  _status = 'Déconnecté';
                });
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statut
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isConnected ? Colors.green[50] : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _isConnected ? Colors.green : Colors.grey,
                ),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Input session ID
            if (!_isConnected) ...[
              TextField(
                controller: _sessionController,
                decoration: const InputDecoration(
                  labelText: 'ID de session',
                  hintText: 'Ex: session123',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _startSession,
                icon: const Icon(Icons.videocam),
                label: const Text('Démarrer la session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 Votre vidéo sera envoyée au serveur LiveKit\n'
                  '   (pas de P2P, enregistrement possible)',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Aperçu vidéo local
            if (_localVideoTrack != null) ...[
              const Text(
                '📹 Votre caméra :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: VideoTrackRenderer(
                      _localVideoTrack!,
                      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      mirror: true,
                    ),
                  ),
                ),
              ),
            ] else if (!_isConnected)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Entrez un ID de session\npour démarrer',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
