// lib/pages/client_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livekit_client/livekit_client.dart' as lk;
import '../services/livekit_service.dart';
import '../widgets/app_bar.dart';

class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  final String clientIdentity = 'client_1';
  bool _isProcessing = false;

  // Méthode pour lancer l'appel (connexion + publication)
  Future<void> _lancerAppel() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final livekitService = Provider.of<LiveKitService>(context, listen: false);

    try {
      if (livekitService.room == null) {
        // Récupère le token et se connecte à la salle
        await livekitService.joinRoom(clientIdentity);
      }

      // Publier la vidéo si la connexion a réussi et si elle n'est pas déjà publiée
      if (livekitService.room != null && livekitService.localTrack == null) {
        await livekitService.publishLocalVideo();
        print("Vidéo du client publiée !");
      }
    } catch (e) {
      print("Erreur lors du lancement de l'appel: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  // Méthode pour déconnecter
  Future<void> _deconnecter() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    final livekitService = Provider.of<LiveKitService>(context, listen: false);

    try {
      await livekitService.disconnect();
      print("Client déconnecté !");
    } catch (e) {
      print("Erreur lors de la déconnexion: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Widget _buildVideoContent(LiveKitService livekitService) {
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
            ],
          ),
        ),
      );
    }

    // Affichage du flux local
    if (livekitService.localTrack != null) {
      return lk.VideoTrackRenderer(
        livekitService.localTrack!,
      );
    }

    // Affichage du statut
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (livekitService.room != null && _isProcessing)
            const CircularProgressIndicator(),
          if (livekitService.room != null && _isProcessing)
            const SizedBox(height: 16),
          Text(
            livekitService.room != null
                ? "Connexion en cours..."
                : "Appuyez sur 'Lancer l'appel' pour démarrer.",
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final livekitService = Provider.of<LiveKitService>(context);
    final bool isConnected = livekitService.room != null &&
        livekitService.room!.connectionState == lk.ConnectionState.connected;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Espace Client'),
      body: Stack(
        children: <Widget>[
          // Fond : La vidéo publiée (locale)
          Positioned.fill(
            child: _buildVideoContent(livekitService),
          ),

          // Bouton d'appel/déconnexion
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: FloatingActionButton.extended(
                onPressed: _isProcessing
                    ? null
                    : (isConnected ? _deconnecter : _lancerAppel),
                label: Text(
                  _isProcessing
                      ? 'Traitement...'
                      : (isConnected ? 'Déconnecter' : 'Lancer l\'appel'),
                ),
                icon: Icon(
                  isConnected ? Icons.call_end : Icons.videocam,
                ),
                backgroundColor: isConnected ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}