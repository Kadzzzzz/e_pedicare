import 'package:flutter/material.dart';
import '../widgets/app_bar.dart'; 
import 'package:camera/camera.dart';

List<CameraDescription> cameras = []; // Liste globale des caméras disponibles

Future<void> initCameras() async { // Fonction pour initialiser les caméras
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Erreur lors de l\'initialisation des caméras : $e');
  }
}



class ClientPage extends StatefulWidget {
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    // Si aucune caméra n'est disponible, ou si la liste est vide (non initialisée)
    if (cameras.isEmpty) {
      await initCameras(); // Tentez d'initialiser les caméras si ce n'est pas déjà fait
      if (cameras.isEmpty) {
        print('Aucune caméra disponible.');
        // Gérer l'absence de caméra (afficher un message, etc.)
        return;
      }
    }

    // Choisir la première caméra disponible (généralement la caméra arrière)
    // Pour la caméra frontale, vous pouvez chercher par `CameraLensDirection.front`
    CameraDescription frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera, // Utilisez la caméra frontale
      ResolutionPreset.medium, // Qualité de la vidéo (low, medium, high, max)
      enableAudio: false, // Active l'audio si nécessaire
    );

    // Initialise le contrôleur. Retourne un Future.
    _initializeControllerFuture = _controller!.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {}); // Met à jour l'UI après l'initialisation
    }).catchError((e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            print('Accès à la caméra refusé.');
            break;
          default:
            print('Erreur caméra inconnue: ${e.description}');
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    // Assurez-vous de disposer du contrôleur lorsque le widget est supprimé.
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Si le contrôleur n'est pas encore initialisé, affichez un indicateur de chargement.
    if (_initializeControllerFuture == null || _controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Espace Praticien'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: const CustomAppBar(title: 'Espace Praticien'),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // Si le Future est terminé, affichez la prévisualisation.
            return CameraPreview(_controller!);
          } else {
            // Sinon, affichez un indicateur de chargement.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}