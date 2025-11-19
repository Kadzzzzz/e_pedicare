import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Page Praticien avec LiveKit - Ultra simple
/// Reçoit le flux vidéo du patient via le serveur LiveKit
/// Pas de P2P - tout passe par le serveur
class LiveKitPractitionerPage extends StatefulWidget {
  const LiveKitPractitionerPage({super.key});

  @override
  State<LiveKitPractitionerPage> createState() => _LiveKitPractitionerPageState();
}

class _LiveKitPractitionerPageState extends State<LiveKitPractitionerPage> {
  // Contrôles UI
  final TextEditingController _sessionController = TextEditingController();
  bool _isConnected = false;
  String _status = 'Non connecté';

  // LiveKit
  Room? _room;
  RemoteVideoTrack? _remoteVideoTrack;
  RemoteParticipant? _patientParticipant;

  @override
  void dispose() {
    _disconnect();
    _sessionController.dispose();
    super.dispose();
  }

  /// Rejoindre une session existante
  Future<void> _joinSession() async {
    final sessionId = _sessionController.text.trim();
    if (sessionId.isEmpty) {
      _setStatus('❌ Entrez un ID de session');
      return;
    }

    _setStatus('🔑 Demande de token...');

    try {
      // 1. Obtenir un token du serveur Flask
      final tokenData = await _getToken(sessionId, 'practitioner');

      _setStatus('📡 Connexion à la room...');

      // 2. Se connecter à la room LiveKit
      _room = await LiveKitClient.connect(
        tokenData['url'],
        tokenData['token'],
        roomOptions: const RoomOptions(
          defaultCameraCaptureOptions: CameraCaptureOptions(
            maxFrameRate: 30,
          ),
        ),
      );

      setState(() {
        _isConnected = true;
      });

      _setStatus('✅ Connecté - En attente du patient...');

      // 3. Écouter les événements de la room
      _room!.addListener(_onRoomUpdate);

      // 4. Vérifier si le patient est déjà présent
      _checkForPatient();

      print('✅ Praticien connecté à la room: $sessionId');

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

  /// Vérifier si le patient est déjà dans la room
  void _checkForPatient() {
    final participants = _room?.remoteParticipants.values.toList() ?? [];
    for (var participant in participants) {
      if (participant.identity == 'patient') {
        _onPatientJoined(participant);
        break;
      }
    }
  }

  /// Écouter les changements de la room
  void _onRoomUpdate() {
    setState(() {
      // Chercher le participant patient
      final participants = _room?.remoteParticipants.values.toList() ?? [];
      for (var participant in participants) {
        if (participant.identity == 'patient') {
          _onPatientJoined(participant);
          return;
        }
      }
    });
  }

  /// Quand le patient rejoint la room
  void _onPatientJoined(RemoteParticipant participant) {
    _patientParticipant = participant;
    _setStatus('👤 Patient détecté - Récupération du stream...');

    // Écouter les tracks du patient
    participant.addListener(() {
      setState(() {
        // Récupérer la vidéo du patient
        for (var pub in participant.videoTrackPublications) {
          if (pub.track != null) {
            _remoteVideoTrack = pub.track as RemoteVideoTrack;
            _setStatus('✅ Réception du stream patient');
            break;
          }
        }
      });
    });

    // Vérifier si le track est déjà disponible
    for (var pub in participant.videoTrackPublications) {
      if (pub.track != null) {
        setState(() {
          _remoteVideoTrack = pub.track as RemoteVideoTrack;
          _setStatus('✅ Réception du stream patient');
        });
        break;
      }
    }
  }

  /// Déconnexion
  Future<void> _disconnect() async {
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
    _remoteVideoTrack = null;
    _patientParticipant = null;
  }

  void _setStatus(String status) {
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍⚕️ Praticien - LiveKit POC'),
        backgroundColor: Colors.green,
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
                  labelText: 'ID de session du patient',
                  hintText: 'Ex: session123',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.tag),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _joinSession,
                icon: const Icon(Icons.login),
                label: const Text('Rejoindre la session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 18),
                  backgroundColor: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 Le flux vidéo passe par le serveur LiveKit\n'
                  '   (enregistrement et traitement possibles)',
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Vidéo du patient
            if (_remoteVideoTrack != null) ...[
              const Text(
                '📹 Stream du patient :',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: VideoTrackRenderer(
                      _remoteVideoTrack!,
                      fit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
            ] else if (_isConnected)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'En attente du stream patient...\n\n'
                        'Participants: ${_room?.remoteParticipants.length ?? 0}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text(
                        'Entrez l\'ID de session\ndu patient pour rejoindre',
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
