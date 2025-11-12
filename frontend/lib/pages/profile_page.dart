import 'package:flutter/material.dart';
import '../widgets/app_bar.dart'; 

class profilepage extends StatelessWidget {
  const profilepage({super.key}); 

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