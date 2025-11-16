import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import du package HTTP
import 'dart:convert'; // Pour convertir JSON en objets Dart
import '../pages/login_page.dart'; // Import de la page de connexion
import 'package:camera/camera.dart'; // Import du package camera
import '../widgets/app_bar.dart';
import 'package:frontend/pages/client_page.dart';

Future<void> initCameras() async {
  // ... (copiez la fonction initCameras de client_page.dart ici ou assurez-vous qu'elle est bien importée)
  // Ou mieux, mettez-la dans client_page.dart et importez-la
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
  } on CameraException catch (e) {
    print('Erreur lors de l\'initialisation des caméras : $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initCameras();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'e-PediCare Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const TestPage(),
    );
  }
}

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _message = 'Pas encore de message';
  bool _isLoading = false;

  Future<void> _fetchMessage() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/hello'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _message = data['message'];
        });
      } else {
        setState(() {
          _message = 'Erreur HTTP: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Erreur de connexion: Backend non disponible.';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: CustomAppBar(title: 'Test Backend Connection'),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Affichage du message (utilise _message)
              Text(
                _message,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Bouton pour déclencher la requête (utilise _isLoading et _fetchMessage)
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchMessage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Appeler le Backend',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
              
              // Bouton de Navigation (Aller à la Connexion)
              const SizedBox(height: 15), 
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginPage(), 
                    ),
                  );
                },
                child: const Text('Aller à la Connexion', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}