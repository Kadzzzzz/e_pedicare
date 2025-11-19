import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'dart:convert';

/// Page Patient POC - Ultra simple
/// - Capture la caméra
/// - Affiche l'aperçu local
/// - Envoie le stream au praticien via WebRTC
class PocPatientPage extends StatefulWidget {
  const PocPatientPage({super.key});

  @override
  State<PocPatientPage> createState() => _PocPatientPageState();
}

class _PocPatientPageState extends State<PocPatientPage> {
  // État de la connexion
  final TextEditingController _sessionController = TextEditingController();
  bool _isConnected = false;
  String _status = 'Non connecté';

  // WebRTC
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();

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
    _localRenderer.dispose();
    _localStream?.dispose();
    _peerConnection?.close();
    _socket?.dispose();
    _sessionController.dispose();
    super.dispose();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
  }

  /// Démarrer la session patient
  Future<void> _startSession() async {
    final sessionId = _sessionController.text.trim();
    if (sessionId.isEmpty) {
      _setStatus('❌ Entrez un ID de session');
      return;
    }

    _sessionId = sessionId;
    _setStatus('🎥 Initialisation de la caméra...');

    // 1. Obtenir l'accès à la caméra
    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'video': {'facingMode': 'user'},
        'audio': true,
      });

      _localRenderer.srcObject = _localStream;
      setState(() {});
      _setStatus('📡 Connexion au serveur...');

      // 2. Se connecter au serveur de signalisation
      _connectToSignalingServer();
    } catch (e) {
      _setStatus('❌ Erreur caméra: $e');
    }
  }

  /// Connexion au serveur WebSocket
  void _connectToSignalingServer() {
    _socket = IO.io('http://localhost:5001', <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.on('connected', (_) {
      print('✅ Connecté au serveur');
      _setStatus('✅ Connecté - En attente du praticien...');

      // Rejoindre en tant que patient
      _socket!.emit('join_as_patient', {'session_id': _sessionId});
    });

    _socket!.on('joined', (data) {
      print('✅ Rejoint la session: $data');
      setState(() => _isConnected = true);
    });

    _socket!.on('practitioner_joined', (data) async {
      print('👨‍⚕️ Praticien a rejoint la session');
      _setStatus('👨‍⚕️ Praticien connecté - Envoi du stream...');

      // Créer l'offre WebRTC
      await _createOffer();
    });

    _socket!.on('signal', (data) async {
      print('📨 Signal reçu: ${data['data']['type']}');
      await _handleSignal(data['data']);
    });

    _socket!.on('peer_disconnected', (_) {
      _setStatus('👋 Praticien déconnecté');
      _peerConnection?.close();
      _peerConnection = null;
    });

    _socket!.on('error', (data) {
      _setStatus('❌ Erreur: ${data['message']}');
    });
  }

  /// Créer une connexion WebRTC et envoyer l'offre
  Future<void> _createOffer() async {
    // Configuration STUN pour le NAT traversal
    final configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    // Ajouter le stream local
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Gérer les candidats ICE
    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate != null) {
        _socket!.emit('signal', {
          'session_id': _sessionId,
          'sender_role': 'patient',
          'data': {
            'type': 'ice-candidate',
            'candidate': candidate.toMap(),
          }
        });
      }
    };

    // Créer l'offre
    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    // Envoyer l'offre au praticien
    _socket!.emit('signal', {
      'session_id': _sessionId,
      'sender_role': 'patient',
      'data': {
        'type': 'offer',
        'sdp': offer.sdp,
      }
    });

    print('📤 Offre WebRTC envoyée');
  }

  /// Gérer les signaux reçus (answer, ice-candidate)
  Future<void> _handleSignal(dynamic data) async {
    final type = data['type'];

    if (type == 'answer') {
      // Recevoir la réponse du praticien
      final answer = RTCSessionDescription(data['sdp'], type);
      await _peerConnection?.setRemoteDescription(answer);
      print('✅ Réponse WebRTC appliquée');
      _setStatus('🎥 Streaming actif vers le praticien');

    } else if (type == 'ice-candidate') {
      // Ajouter le candidat ICE
      final candidate = RTCIceCandidate(
        data['candidate']['candidate'],
        data['candidate']['sdpMid'],
        data['candidate']['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
    }
  }

  void _setStatus(String status) {
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📱 Patient - POC WebRTC'),
        backgroundColor: Colors.blue,
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
            ],

            const SizedBox(height: 20),

            // Aperçu vidéo local
            if (_localStream != null) ...[
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
                    child: RTCVideoView(_localRenderer, mirror: true),
                  ),
                ),
              ),
            ] else
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
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
