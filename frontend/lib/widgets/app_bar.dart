import 'package:flutter/material.dart';
import 'package:frontend/pages/client_page.dart';
import '../pages/login_page.dart'; 
import '../main.dart'; 
import '../pages/profile_page.dart'; 
import '../pages/praticien_page.dart';


class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const CustomAppBar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      // Ajout des actions de navigation (boutons dans la barre)
      actions: <Widget>[
        // Bouton Home/TestPage
        TextButton(
          onPressed: () {
            // Remplace la page actuelle par la HomePage (TestPage)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const TestPage()),
            );
          },
          child: const Text('Accueil', style: TextStyle(color: Colors.white)),
        ),
        
        // Bouton Connexion/LoginPage
        TextButton(
          onPressed: () {
            // Remplace la page actuelle par la LoginPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          },
          child: const Text('Connexion', style: TextStyle(color: Colors.white)),
        ),

        // Bouton ClientPage
        TextButton(
          onPressed: () {
            // Remplace la page actuelle par la LoginPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const ClientPage()),
            );
          },
          child: const Text('Client', style: TextStyle(color: Colors.white)),
        ),

        // Bouton PraticienPage
        TextButton(
          onPressed: () {
            // Remplace la page actuelle par la LoginPage
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const PraticienPage()),
            );
          },
          child: const Text('Praticien', style: TextStyle(color: Colors.white)),
        ),

        // Bouton Profil
        TextButton(
           onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
             print('Navigation vers Profil (Page ProfilePage non créée)');
           },
           child: const Text('Profil', style: TextStyle(color: Colors.white)),
         ),
      ],
    );
  }

  // Nécessaire pour implémenter PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}