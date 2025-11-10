import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import du package HTTP
import 'dart:convert'; // Pour convertir JSON en objets Dart
import 'pages/login_page.dart'; // Import de la page de connexion


void main() {
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
  // 1. DÉCLARATION DES VARIABLES D'ÉTAT ET DE LA FONCTION D'APPEL (Correct)
  String _message = 'Pas encore de message';
  bool _isLoading = false;

  Future<void> _fetchMessage() async {
    // Le contenu de la fonction _fetchMessage
    setState(() {
      _isLoading = true;
    });
    // ... votre requête HTTP ...
    // ...
  }

  // 2. MÉTHODE BUILD MANQUANTE (OBLIGATOIRE)
  @override
  Widget build(BuildContext context) {
    // TOUT LE CODE DE L'INTERFACE UTILISATEUR COMMENCE ICI

    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Backend Connection'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
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