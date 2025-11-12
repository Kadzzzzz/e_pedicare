import 'package:flutter/material.dart';
import '../widgets/app_bar.dart'; 


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

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
              const TextField(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 20),

              // Champ de texte pour le Mot de Passe
              const TextField(
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
                onPressed: () {
                  // TODO: Ajouter ici la logique d'appel à l'API Flask /api/auth/login
                  print('Tentative de connexion...');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Se Connecter'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}