import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:provider/provider.dart'; // Nécessaire pour accéder au LiveKitService
import '../widgets/app_bar.dart'; 
import 'package:livekit_client/livekit_client.dart' hide ConnectionState;
import '../services/livekit_service.dart'; // Assurez-vous que ce chemin est correct

// La liste des caméras (déjà existante)
List<CameraDescription> cameras = []; 

// Fonction pour initialiser les caméras (déjà existante)
Future<void> initCameras() async { 
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Erreur lors de l\'initialisation des caméras : $e');
  }
}

class ClientPage extends StatefulWidget {
  // Suppression du 'required this.titre' pour correspondre à votre constructeur actuel
  const ClientPage({super.key}); 

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  final String clientIdentity = 'client_1';

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    
    // Initialiser la connexion LiveKit lors de l'ouverture de la page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final livekitService = Provider.of<LiveKitService>(context, listen: false);
      if (livekitService.room == null) {
        // Optionnel : Connexion automatique ou attente du bouton
      }
    });
  }
  
  // --- 2. MÉTHODE DE L'APPEL LIVEKIT ---
  void _lancerAppel(BuildContext context) async {
    final livekitService = Provider.of<LiveKitService>(context, listen: false);
    
    if (livekitService.room == null) {
        // ÉTAPE 1 : Connexion à la salle LiveKit
        await livekitService.joinRoom(clientIdentity);
    }

    if (livekitService.room != null) {
        // ÉTAPE 2 : PUBLICATION DU FLUX VIDÉO
        // Le flux de la caméra sera publié via le SDK LiveKit
        await livekitService.publishLocalVideo(); 
        print("Vidéo du client publiée dans la salle !");
    }
  }

  // Méthode _initializeCamera existante
  Future<void> _initializeCamera() async {
    // ... (votre code d'initialisation existant)
    if (cameras.isEmpty) {
      await initCameras(); 
      if (cameras.isEmpty) {
        print('Aucune caméra disponible.');
        return;
      }
    }

    // Gérer l'absence de caméra frontale pour éviter une erreur
    CameraDescription selectedCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first, // Fallback à la première caméra
    );

    _controller = CameraController(
      selectedCamera, 
      ResolutionPreset.medium, 
      enableAudio: true, // IMPORTANT : L'audio doit être activé pour le chat vidéo
    );

    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (!mounted) return;
      setState(() {}); 
    }).catchError((e) {
      if (e is CameraException) {
        print('Erreur caméra: ${e.description}');
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    // OPTIONNEL : Déconnecter LiveKit lorsque la page est quittée
    // final livekitService = Provider.of<LiveKitService>(context, listen: false);
    // livekitService.disconnect(); 
    super.dispose();
  }

  // --- 3. MODIFICATION DE LA MÉTHODE BUILD ---
  @override
  Widget build(BuildContext context) {
    // Vérification du statut de la caméra
    if (_initializeControllerFuture == null || _controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(
        appBar: CustomAppBar(title: 'Espace Client'), // Utilisation de CustomAppBar
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Espace Client'),
      
      // Utilisation d'un Stack pour superposer le bouton sur la vidéo
      body: Stack(
        children: <Widget>[
          // Fond (1) : La prévisualisation de la caméra qui prend tout l'espace
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // Affiche la caméra avec un AspectRatio pour éviter la déformation
                  return AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: CameraPreview(_controller!),
                  );
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),

          // Bouton (2) : Positionné au bas de l'écran
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: FloatingActionButton.extended(
                onPressed: () => _lancerAppel(context), 
                label: const Text('Lancer l\'appel et Publier'),
                icon: const Icon(Icons.send),
                backgroundColor: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}