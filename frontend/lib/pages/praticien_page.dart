import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import '../widgets/app_bar.dart';
import '../services/livekit_service.dart';
import '../services/api_service.dart';

/// Page Praticien - Réception du flux vidéo du client
///
/// Cette page permet au praticien de rejoindre une session vidéo
/// créée par un parent/client et de visualiser la vidéo en temps réel
class PraticienPage extends StatefulWidget {
  const PraticienPage({super.key});

  @override
  State<PraticienPage> createState() => _PraticienPageState();
}

class _PraticienPageState extends State<PraticienPage> {
  final LiveKitService _liveKitService = LiveKitService();
  final ApiService _apiService = ApiService();

  bool _isConnecting = false;
  bool _isConnected = false;
  String? _roomName;
  String? _errorMessage;

  // Contrôleurs pour le formulaire
  final TextEditingController _roomNameController = TextEditingController();
  final TextEditingController _practitionerNameController = TextEditingController();

  // Liste des flux vidéo des participants distants (clients)
  List<VideoTrack> _remoteVideoTracks = [];

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
    _practitionerNameController.dispose();
    super.dispose();
  }

  void _onLiveKitUpdate() {
    if (mounted) {
      setState(() {
        _isConnected = _liveKitService.isConnected;
        // Récupérer tous les flux vidéo distants
        _remoteVideoTracks = _liveKitService.getAllRemoteVideoTracks();
      });
    }
  }

  /// Rejoindre une session vidéo existante
  Future<void> _joinVideoSession() async {
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
      final practitionerName = _practitionerNameController.text.trim().isEmpty
          ? 'Praticien'
          : _practitionerNameController.text.trim();

      // Rejoindre la session via le backend
      final response = await _apiService.joinVideoSession(
        roomName: roomName,
        participantName: practitionerName,
      );

      final livekitUrl = response['livekit_url'];
      final token = response['token'];

      // Se connecter à LiveKit sans caméra (juste pour recevoir)
      // Le praticien n'envoie pas de vidéo pour le POC
      await _liveKitService.connect(
        url: livekitUrl,
        token: token,
        enableCamera: false,
        enableMicrophone: false,
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

  /// Quitter la session vidéo
  Future<void> _leaveVideoSession() async {
    await _liveKitService.disconnect();

    setState(() {
      _isConnected = false;
      _roomName = null;
      _remoteVideoTracks.clear();
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Session quittée'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Espace Praticien'),
      body: _isConnected ? _buildConnectedView() : _buildJoinForm(),
    );
  }

  /// Vue quand connecté - Affiche la vidéo du client
  Widget _buildConnectedView() {
    return Column(
      children: [
        // Affichage du flux vidéo distant
        Expanded(
          child: Container(
            color: Colors.black,
            child: _remoteVideoTracks.isEmpty
                ? _buildWaitingView()
                : _buildRemoteVideoView(),
          ),
        ),

        // Informations de session
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.green.shade50,
          child: Row(
            children: [
              const Icon(Icons.video_library, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Session: $_roomName',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Participants: ${_liveKitService.remoteParticipants.length + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (_remoteVideoTracks.isNotEmpty)
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
                        'RÉCEPTION',
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton quitter
              ElevatedButton.icon(
                onPressed: _leaveVideoSession,
                icon: const Icon(Icons.exit_to_app),
                label: const Text('Quitter la session'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Vue d'attente - En attente du flux vidéo
  Widget _buildWaitingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 24),
          const Text(
            'En attente du flux vidéo...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Assurez-vous que le client a démarré la session',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// Vue avec la vidéo distante
  Widget _buildRemoteVideoView() {
    // Pour le POC, on affiche le premier flux vidéo
    // Plus tard, on pourra afficher plusieurs flux en grille
    final videoTrack = _remoteVideoTracks.first;

    return Stack(
      children: [
        // Flux vidéo principal
        VideoTrackRenderer(
          videoTrack,
          fit: VideoViewFit.contain,
        ),

        // Indicateur de flux actif
        Positioned(
          top: 16,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
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
        ),

        // Compteur de participants
        if (_remoteVideoTracks.length > 1)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_remoteVideoTracks.length} flux vidéo',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Formulaire pour rejoindre une session
  Widget _buildJoinForm() {
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
                  Icons.personal_video,
                  size: 64,
                  color: Colors.green,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Rejoindre une session',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Entrez le nom de la session créée par le parent',
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

                // Nom du praticien (optionnel)
                TextField(
                  controller: _practitionerNameController,
                  decoration: const InputDecoration(
                    labelText: 'Votre nom (optionnel)',
                    hintText: 'ex: Dr. Martin',
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

                // Bouton rejoindre
                ElevatedButton.icon(
                  onPressed: _isConnecting ? null : _joinVideoSession,
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
                    _isConnecting ? 'Connexion en cours...' : 'Rejoindre la session',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),

                // Note d'information
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Colors.green.shade700, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Vous recevrez le flux vidéo du client en temps réel une fois connecté.',
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
