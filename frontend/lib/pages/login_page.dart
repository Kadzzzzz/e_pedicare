import 'package:flutter/material.dart';
import '../widgets/app_bar.dart'; 
import 'package:http/http.dart' as http; 
import 'dart:convert'; 
import '../main.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _statusMessage = 'Veuillez vous connecter.';
  bool _isLoading = false;

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Connexion en cours...';
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
        setState(() {
          _statusMessage = 'Veuillez remplir tous les champs.';
          _isLoading = false;
        });
        return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/auth/login'), 
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
      
      // TODO: Stocker le token JWT (data['access_token']) localement

        setState(() {
          _statusMessage = data['connexion réussie']; 
        });

        Navigator.pushReplacement(
            context,
           MaterialPageRoute(builder: (context) => const TestPage()), 
        );

      } else if (response.statusCode == 401) {//erreur de connexion
        final errorData = jsonDecode(response.body);
        setState(() {
          _statusMessage = errorData['message']; 
        });
      } else {
        setState(() {
          _statusMessage = 'Erreur serveur: ${response.statusCode}.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Erreur de connexion. Vérifiez le serveur Flask.';
      });
   }

    setState(() {
      _isLoading = false;
    });
  }

  // NETTOYAGE DES CONTRÔLEURS
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Connexion Utilisateur'),
      // Le corps de la page
      body: Center(
        child: SingleChildScrollView( // Permet de faire défiler le formulaire si l'écran est petit (mobile)
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch, // Étire les widgets TextField
            children: <Widget>[
              const Text(
                'Bienvenue',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Champ de texte pour l'Email
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              // Champ de texte pour le Mot de Passe
              TextField(
                controller: _passwordController,
                obscureText: true, // Cache le texte tapé
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 30),
              // Bouton de Connexion
              ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin, 
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                      ) 
                    : const Text('Se Connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
