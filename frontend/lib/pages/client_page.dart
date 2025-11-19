// lib/pages/client_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 🚨 V2.5.3 : Masquer ConnectionState pour éviter les conflits
import 'package:livekit_client/livekit_client.dart' hide ConnectionState; 
import '../services/livekit_service.dart';
import '../widgets/app_bar.dart'; // Assurez-vous que CustomAppBar existe

// Remplacez par votre TestPage ou laissez la page simplifiée
class TestPage extends StatelessWidget {
  const TestPage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text("Page d'accueil")));
  }
}

class ClientPage extends StatelessWidget {
  const ClientPage({super.key});

  final String clientIdentity = 'client_1'; 

  // Méthode pour lancer l'appel (connexion + publication)
  void _lancerAppel(BuildContext context) async {
    final livekitService = Provider.of<LiveKitService>(context, listen: false);
    
    if (livekitService.room == null) {
        // Récupère le token et se connecte à la salle
        await livekitService.joinRoom(clientIdentity); 
    }

    // Publier la vidéo si la connexion a réussi et si elle n'est pas déjà publiée
    if (livekitService.room != null && livekitService.localTrack == null) {
        await livekitService.publishLocalVideo(); 
        print("Vidéo du client publiée !");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final livekitService = Provider.of<LiveKitService>(context); // Écoute les changements

    Widget buildVideoContent() {
      if (livekitService.error != null) {
        return Center(child: Text('Erreur LiveKit: ${livekitService.error}', textAlign: TextAlign.center));
      }
      
      // 🚨 Affichage du flux local via LiveKit VideoTrackRenderer
      if (livekitService.localTrack != null) {
        return VideoTrackRenderer(livekitService.localTrack as VideoTrack);
      }
      
      // Affichage du statut
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (livekitService.room != null) const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(livekitService.room != null ? "Connexion en cours..." : "Appuyez sur Appeler pour démarrer.")
          ],
        ),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Espace Client'),
      
      body: Stack(
        children: <Widget>[
          // Fond : La vidéo publiée (locale)
          Positioned.fill(
            child: buildVideoContent(),
          ),

          // Bouton d'appel
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: FloatingActionButton.extended(
                onPressed: () => _lancerAppel(context), 
                label: Text(livekitService.room?.localParticipant?.isPublishing ?? false 
                            ? 'Déconnecter' // Si déjà connecté, le bouton devient Déconnexion
                            : 'Lancer l\'appel'),
                icon: const Icon(Icons.videocam),
                backgroundColor: livekitService.room != null ? Colors.red : Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }
}