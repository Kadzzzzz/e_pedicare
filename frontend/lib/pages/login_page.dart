// Dans lib/pages/login_page.dart

import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key}); // <-- C'EST CETTE LIGNE

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion')),
      body: const Center(child: Text('Page de Connexion')),
    );
  }
}