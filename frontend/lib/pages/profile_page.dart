import 'package:flutter/material.dart';
import '../widgets/app_bar.dart'; 

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Utilisation du bandeau commun
      appBar: const CustomAppBar(title: 'Page de Profil'), 
      
      body: const Center(
        child: Text('corps de base'),
      ),
    );
  }
}