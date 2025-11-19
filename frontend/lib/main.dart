import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../pages/login_page.dart';
import '../widgets/app_bar.dart';
import 'package:camera/camera.dart';
import 'package:frontend/pages/client_page.dart';
import 'package:provider/provider.dart';
import 'package:frontend/services/livekit_service.dart';

// Variable globale pour stocker les caméras disponibles
List<CameraDescription> cameras = [];

Future<void> initCameras() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    cameras = await availableCameras();
    print('Caméras initialisées: ${cameras.length} caméra(s) trouvée(s)');
  } on CameraException catch (e) {
    print('Erreur lors de l\'initialisation des caméras : $e');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initCameras();
  runApp(
    ChangeNotifierProvider(
      create: (context) => LiveKitService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'e-PediCare Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const TestPage(),
      debugShowCheckedModeBanner: false,
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
      _message = 'Connexion en cours...';
    });

    try {
      final response = await http.get(
        Uri.parse('http://localhost:5000/hello'), // Pour émulateur Android
        // Pour iOS simulateur, utilisez: http://localhost:5000/hello
        // Pour appareil réel, utilisez l'IP de votre machine
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Délai de connexion dépassé');
        },
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
        _message = 'Erreur de connexion: ${e.toString()}';
      });
      print('Erreur détaillée: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Test Backend Connection'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Affichage du message
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  _message,
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),

              // Bouton pour déclencher la requête
              ElevatedButton(
                onPressed: _isLoading ? null : _fetchMessage,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
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
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                ),
                child: const Text(
                  'Aller à la Connexion',
                  style: TextStyle(fontSize: 16),
                ),
              ),

              // Bouton pour tester LiveKit (Client Page)
              const SizedBox(height: 15),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ClientPage(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Tester LiveKit (Client)',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}