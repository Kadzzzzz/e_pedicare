// Assurez-vous d'utiliser un widget pour gérer l'état (ChangeNotifierProvider/Provider)
import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:provider/provider.dart'; // Si vous utilisez Provider
import '../services/livekit_service.dart';
import '../widgets/app_bar.dart'; 

class PraticienPage extends StatelessWidget {
  const PraticienPage({super.key});
  
 final String praticienIdentity = 'praticien_1';

  @override
  Widget build(BuildContext context) {
    final livekitService = Provider.of<LiveKitService>(context, listen: false);
    
    // Tentative de connexion si pas déjà connecté
    if (livekitService.room == null) {
      livekitService.joinRoom(praticienIdentity);
    }
    
    return Scaffold(
      appBar: CustomAppBar(title: 'Espace Praticien'), // Utilisation de CustomAppBar
      body: Consumer<LiveKitService>(
        builder: (context, service, child) {
          if (service.error != null) {
            return Center(child: Text('Erreur: ${service.error}'));
          }
          
          if (service.room?.localParticipant == null || service.room!.localParticipant.isConnecting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          // --- Affichage de la vidéo du Client ---
          if (service.remoteTrack != null) {
            // VideoRenderer est le widget qui affiche le flux LiveKit
            return VideoRenderer(service.remoteTrack as VideoTrack);
          } else {
            return const Center(child: Text('En attente du Client...'));
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: livekitService.disconnect,
        child: const Icon(Icons.call_end),
      ),
    );
  }
}

// NOTE : N'oubliez pas d'envelopper votre MaterialApp avec le ChangeNotifierProvider :
/*
void main() {
  runApp(ChangeNotifierProvider(
    create: (context) => LiveKitService(livekitUrl),
    child: const MonApplication(),
  ));
}
*/