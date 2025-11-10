import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import du package HTTP
import 'dart:convert'; // Pour convertir JSON en objets Dart

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
  // Variables d'état
  String _message = 'Pas encore de message';
  bool _isLoading = false;

  // Fonction pour appeler le backend
  Future<void> _fetchMessage() async {
    // 1. On informe l'interface qu'on commence le chargement
    setState(() {
      _isLoading = true;
    });

    try {
      // 2. On fait la requête HTTP GET vers notre backend
      final response = await http.get(
        Uri.parse('http://localhost:5000/hello'),
      );

      // 3. On vérifie si la requête a réussi (code 200 = OK)
      if (response.statusCode == 200) {
        // 4. On décode le JSON reçu
        final data = jsonDecode(response.body);

        // 5. On met à jour l'interface avec le message reçu
        setState(() {
          _message = data['message'];
          _isLoading = false;
        });
      } else {
        // Si le code n'est pas 200, il y a une erreur
        setState(() {
          _message = 'Erreur: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      // 6. Si quelque chose plante (pas de connexion, etc.)
      setState(() {
        _message = 'Erreur de connexion: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
              // Affichage du message
              Text(
                _message,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
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
            ],
          ),
        ),
      ),
    );
  }
}