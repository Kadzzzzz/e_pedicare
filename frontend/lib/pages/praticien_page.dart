// lib/pages/praticien_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:livekit_client/livekit_client.dart';
import '../services/livekit_service.dart';
import '../widgets/app_bar.dart'; 

class PraticienPage extends StatelessWidget {
  final String titre; 
  const PraticienPage({super.key, this.titre = 'Espace Praticien'});

  final String praticienIdentity = 'praticien_1'; 
  
  // Initialisation automatique de la connexion
  void _connecter(BuildContext context) {
    final livekitService = Provider.of<LiveKitService>(context, listen: false);
    if (livekitService.room == null) {
      livekitService.joinRoom(praticienIdentity);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tenter la connexion dès que le widget est construit
    _connecter(context); 
    final livekitService = Provider.of<LiveKitService>(context); // Écoute les changements

    Widget buildRemoteVideo() {
      if (livekitService.error != null) {
        return Center(child: Text('Erreur LiveKit: ${livekitService.error}', textAlign: TextAlign.center));
      }

      // 🚨 Vérifier l'état de connexion de la Room
      if (livekitService.room == null || livekitService.room!.connectionState != RoomState.connected) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text("Connexion en cours en tant que ${praticienIdentity}...")
              ],
            ),
          );
      }

      // Si le flux distant est reçu, affichez-le
      if (livekitService.remoteTrack != null) {
        // 🚨 V2.5.3 : Widget pour afficher la piste vidéo distante
        return VideoTrackRenderer(livekitService.remoteTrack as VideoTrack);
      }
      
      // En attente
      return const Center(child: Text('Connecté. En attente du flux vidéo du Client...'));
    }

    return Scaffold(
      appBar: CustomAppBar(title: titre),
      body: buildRemoteVideo(),
      floatingActionButton: FloatingActionButton(
        onPressed: livekitService.disconnect,
        child: const Icon(Icons.call_end),
        backgroundColor: Colors.red,
      ),
    );
  }
}