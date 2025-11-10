// lib/login_page.dart
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Déclarer les contrôleurs pour les champs de texte
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // 2. Méthode pour gérer la tentative de connexion
  void _handleLogin() {
    final String email = _emailController.text;
    final String password = _passwordController.text;

    // TODO: 3. Appeler le backend ici (comme dans votre exemple précédent)
    print('Tentative de connexion avec Email: $email et Mot de passe: $password');
    // Une fois connecté, vous naviguez vers une autre page.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Champ Email
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Adresse Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 20),

            // Champ Mot de passe
            TextField(
              controller: _passwordController,
              obscureText: true, // Cache le texte tapé
              decoration: const InputDecoration(
                labelText: 'Mot de passe',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 30),

            // Bouton de connexion
            ElevatedButton(
              onPressed: _handleLogin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50), // Bouton pleine largeur
              ),
              child: const Text('Se Connecter', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }

  // N'oubliez pas de disposer des contrôleurs
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}