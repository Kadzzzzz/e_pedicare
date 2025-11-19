import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

/// Page Praticien POC - Ultra simple
/// - Se connecte avec un ID de session
/// - Reçoit et affiche le stream du patient
class PocPractitionerPage extends StatefulWidget {
  const PocPractitionerPage({super.key});

  @override
  State<PocPractitionerPage> createState() => _PocPractitionerPageState();
}

class _PocPractitionerPageState extends State<PocPractitionerPage> {
  // État de la connexion
  final TextEditingController _sessionController = TextEditingController();
  bool _isConnected = false;
  String _status = 'Non connecté';

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _remoteStream;
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  // WebSocket
  IO.Socket? _socket;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _initRenderers();
  }

  @override
  void dispose() {
    _remoteRenderer.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
    _socket?.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _remoteRenderer.initialize();
  }

  /// Rejoindre une session existante
  Future<void> _joinSession() async {
    final sessionId = _sessionController.text.trim();
    if (sessionId.isEmpty) {
      _setStatus('❌ Entrez un ID de session');
      return;
    }

    _sessionId = sessionId;
    _setStatus('📡 Connexion au serveur...');

    // Se connecter au serveur de signalisation
    _connectToSignalingServer();
  }

  /// Connexion au serveur WebSocket
  void _connectToSignalingServer() {
    _socket = IO.io('http://localhost:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.on('connected', (_) {
      print('✅ Connecté au serveur');
      _setStatus('✅ Connecté - Rejoindre la session...');

      // Rejoindre en tant que praticien
      _socket!.emit('join_as_practitioner', {'session_id': _sessionId});
    });

    _socket!.on('joined', (data) {
      print('✅ Rejoint la session: $data');
      setState(() => _isConnected = true);
      _setStatus('👤 En attente du patient...');
    });

    _socket!.on('patient_joined', (data) {
      print('👤 Patient dans la session');
      _setStatus('👤 Patient présent - En attente du stream...');
    });

    _socket!.on('signal', (data) async {
      print('📨 Signal reçu: ${data['data']['type']}');
      await _handleSignal(data['data']);
    });

    _socket!.on('peer_disconnected', (_) {
      _setStatus('👋 Patient déconnecté');
      _remoteRenderer.srcObject = null;
      _peerConnection?.close();
      _peerConnection = null;
      setState(() {});
    });

    _socket!.on('error', (data) {
      _setStatus('❌ Erreur: ${data['message']}');
    });
  }

  /// Gérer les signaux reçus (offer, ice-candidate)
  Future<void> _handleSignal(dynamic data) async {
    final type = data['type'];

    if (type == 'offer') {
      // Recevoir l'offre du patient et créer la réponse
      _setStatus('📥 Offre reçue - Configuration...');
      await _handleOffer(data['sdp']);

    } else if (type == 'ice-candidate') {
      // Ajouter le candidat ICE
      if (_peerConnection != null) {
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        await _peerConnection?.addCandidate(candidate);
      }
    }
  }

  /// Gérer l'offre WebRTC et créer la réponse
  Future<void> _handleOffer(String sdp) async {
    // Configuration STUN
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    // Gérer les candidats ICE
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        _socket!.emit('signal', {
          'session_id': _sessionId,
          'sender_role': 'practitioner',
          'data': {
            'type': 'ice-candidate',
            'candidate': candidate.toMap(),
          }
        });
      }
    };

    // Gérer le stream distant
    _peerConnection!.onTrack = (event) {
      print('🎥 Stream reçu du patient!');
      if (event.streams.isNotEmpty) {
        setState(() {
          _remoteStream = event.streams[0];
          _remoteRenderer.srcObject = _remoteStream;
        });
        _setStatus('✅ Réception du stream patient');
      }
    };

    // Appliquer l'offre
    final offer = RTCSessionDescription(sdp, 'offer');
    await _peerConnection!.setRemoteDescription(offer);

    // Créer la réponse
    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    // Envoyer la réponse au patient
    _socket!.emit('signal', {
      'session_id': _sessionId,
      'sender_role': 'practitioner',
      'data': {
        'type': 'answer',
        'sdp': answer.sdp,
      }
    });

    print('📤 Réponse WebRTC envoyée');
  }

  void _setStatus(String status) {
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍⚕️ Praticien - POC WebRTC'),
        backgroundColor: Colors.green,
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
            ],

            const SizedBox(height: 20),

            // Vidéo du patient
            if (_remoteStream != null) ...[
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
                    child: RTCVideoView(_remoteRenderer),
                  ),
                ),
              ),
            ] else if (_isConnected)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'En attente du stream patient...',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
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
