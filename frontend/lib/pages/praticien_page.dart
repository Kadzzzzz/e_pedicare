// lib/pages/praticien_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../services/livekit_service.dart';
import '../widgets/app_bar.dart'; 

class PraticienPage extends StatefulWidget {
  final String titre; 
  const PraticienPage({super.key, this.titre = 'Espace Praticien'});

  @override
  State<PraticienPage> createState() => _PraticienPageState();
}

class _PraticienPageState extends State<PraticienPage> {
  final String praticienIdentity = 'praticien_1';
  bool _isConnecting = false;
  
  @override
  void initState() {
    super.initState();
    // Connexion après que le widget soit construit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connecter();
    });
  }

  // Initialisation de la connexion
  Future<void> _connecter() async {
    if (_isConnecting) return;
    
    setState(() {
      _isConnecting = true;
    });

    final livekitService = Provider.of<LiveKitService>(context, listen: false);
    
    if (livekitService.room == null) {
      await livekitService.joinRoom(praticienIdentity);
    }
    
    if (mounted) {
      setState(() {
        _isConnecting = false;
      });
    }
  }

  Widget _buildRemoteVideo(LiveKitService livekitService) {
    // Gestion des erreurs
    if (livekitService.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Erreur LiveKit',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                livekitService.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _connecter,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    // Vérifier l'état de connexion de la Room
    if (livekitService.room == null || 
        livekitService.room!.connectionState != lk.ConnectionState.connected) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              "Connexion en cours en tant que $praticienIdentity...",
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    // Si le flux distant est reçu, l'afficher
    if (livekitService.remoteTrack != null) {
      return lk.VideoTrackRenderer(
        livekitService.remoteTrack!,
      );
    }
    
    // En attente du flux
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Connecté',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'En attente du flux vidéo du Client...',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final livekitService = Provider.of<LiveKitService>(context);

    return Scaffold(
      appBar: CustomAppBar(title: widget.titre),
      body: _buildRemoteVideo(livekitService),
      floatingActionButton: livekitService.room != null
          ? FloatingActionButton(
              onPressed: () async {
                await livekitService.disconnect();
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              backgroundColor: Colors.red,
              child: const Icon(Icons.call_end),
            )
          : null,
    );
  }
}