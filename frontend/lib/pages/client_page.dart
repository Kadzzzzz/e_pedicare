import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../widgets/app_bar.dart';
import '../services/livekit_service.dart';
import '../services/api_service.dart';

/// Page Client/Parent - Streaming vidéo vers le praticien
///
/// Cette page permet aux parents de démarrer une session vidéo
/// avec leur enfant et de streamer la vidéo au praticien
class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final LiveKitService _liveKitService = LiveKitService();
  final ApiService _apiService = ApiService();

  bool _isConnecting = false;
  bool _isConnected = false;
  String? _roomName;
  String? _errorMessage;

  // Contrôleurs pour le formulaire
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _parentNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _apiService.init();

    // Écouter les changements du service LiveKit
    _liveKitService.addListener(_onLiveKitUpdate);
  }

  @override
  void dispose() {
    _liveKitService.removeListener(_onLiveKitUpdate);
    _liveKitService.disconnect();
    _roomNameController.dispose();
    _parentNameController.dispose();
    super.dispose();
  }

  void _onLiveKitUpdate() {
    if (mounted) {
      setState(() {
        _isConnected = _liveKitService.isConnected;
      });
    }
  }

  /// Démarrer une session vidéo
  Future<void> _startVideoSession() async {
    if (_roomNameController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Veuillez entrer un nom de session';
      });
      return;
    }

    setState(() {
      _isConnecting = true;
      _errorMessage = null;
    });

    try {
      final roomName = _roomNameController.text.trim();
      final parentName = _parentNameController.text.trim().isEmpty
          ? 'Parent'
          : _parentNameController.text.trim();

      // Créer la session via le backend
      final response = await _apiService.createVideoSession(
        roomName: roomName,
      );

      final livekitUrl = response['livekit_url'];
      final token = response['token'];

      // Se connecter à LiveKit avec caméra et micro activés
      await _liveKitService.connect(
        url: livekitUrl,
        token: token,
        enableCamera: true,
        enableMicrophone: true,
      );

      setState(() {
        _isConnecting = false;
        _isConnected = true;
        _roomName = roomName;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connecté à la session: $roomName'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _errorMessage = 'Erreur: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de connexion: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Terminer la session vidéo
  Future<void> _endVideoSession() async {
    if (_roomName != null) {
      try {
        await _apiService.endVideoSession(roomName: _roomName!);
      } catch (e) {
        debugPrint('Erreur lors de la fin de session: $e');
      }
    }

    await _liveKitService.disconnect();

    setState(() {
      _isConnected = false;
      _roomName = null;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session terminée'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Espace Parent/Client'),
      body: _isConnected ? _buildConnectedView() : _buildConnectionForm(),
    );
  }

  /// Vue quand connecté - Affiche la vidéo locale et les contrôles
  Widget _buildConnectedView() {
    return Column(
      children: [
        // Affichage de la vidéo locale
        Expanded(
          child: Container(
            color: Colors.black,
            child: _liveKitService.localVideoTrack != null
                ? VideoTrackWidget(
                    _liveKitService.localVideoTrack!,
                    fit: BoxFit.contain,
                  )
                : const Center(
                    child: Text(
                      'Caméra désactivée',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
          ),
        ),

        // Informations de session
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.blue.shade50,
          child: Row(
            children: [
              const Icon(Icons.videocam, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Session: $_roomName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'EN DIRECT',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Contrôles
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Basculer caméra avant/arrière
              _buildControlButton(
                icon: Icons.flip_camera_ios,
                label: 'Basculer',
                onPressed: () => _liveKitService.switchCamera(),
                color: Colors.blue,
              ),

              // Toggle caméra
              _buildControlButton(
                icon: _liveKitService.isCameraEnabled
                    ? Icons.videocam
                    : Icons.videocam_off,
                label: 'Caméra',
                onPressed: () => _liveKitService.toggleCamera(),
                color: _liveKitService.isCameraEnabled
                    ? Colors.blue
                    : Colors.grey,
              ),

              // Toggle micro
              _buildControlButton(
                icon: _liveKitService.isMicrophoneEnabled
                    ? Icons.mic
                    : Icons.mic_off,
                label: 'Micro',
                onPressed: () => _liveKitService.toggleMicrophone(),
                color: _liveKitService.isMicrophoneEnabled
                    ? Colors.blue
                    : Colors.grey,
              ),

              // Terminer la session
              _buildControlButton(
                icon: Icons.call_end,
                label: 'Terminer',
                onPressed: _endVideoSession,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Widget pour un bouton de contrôle
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
            backgroundColor: color,
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// Formulaire de connexion - Avant de démarrer la session
  Widget _buildConnectionForm() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Icône et titre
                const Icon(
                  Icons.video_call,
                  size: 64,
                  color: Colors.blue,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Démarrer une session',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Créez une session vidéo pour que le praticien puisse vous rejoindre',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Nom de la session
                TextField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom de la session *',
                    hintText: 'ex: session-enfant-123',
                    prefixIcon: Icon(Icons.meeting_room),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Nom du parent (optionnel)
                TextField(
                  controller: _parentNameController,
                  decoration: const InputDecoration(
                    labelText: 'Votre nom (optionnel)',
                    hintText: 'ex: Alice Martin',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),

                // Message d'erreur
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Bouton de démarrage
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _startVideoSession,
                  icon: _isConnecting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.video_call),
                  label: Text(
                    _isConnecting ? 'Connexion en cours...' : 'Démarrer la session',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Note d'information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Le praticien devra entrer le même nom de session pour vous rejoindre.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
