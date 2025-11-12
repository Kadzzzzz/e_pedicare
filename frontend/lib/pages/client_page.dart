import 'package:flutter/material.dart';
import '../widgets/app_bar.dart'; 

// 1. Le StatefulWidget : Il est immuable et crée l'objet State.
class ClientPage extends StatefulWidget {
  // Le constructeur est souvent utilisé pour passer des données (arguments)
  const ClientPage({super.key});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

// 2. Le State : C'est ici que les données qui changent (l'état) et l'UI sont gérées.
class _ClientPageState extends State<ClientPage> {
  // ** Déclaration de l'état (données qui peuvent changer) **
  int _compteur = 0;

  // ** Méthode pour modifier l'état **
  void _incrementerCompteur() {
    // setState notifie Flutter que l'état a changé et qu'il faut reconstruire l'UI.
    setState(() {
      _compteur++;
    });
  }

  // ** La méthode build() : Décrit l'UI **
  @override
  Widget build(BuildContext context) {
    // La propriété 'widget' permet d'accéder aux propriétés du StatefulWidget (MaPageDynamique)
    return Scaffold(
      appBar: const CustomAppBar(title: 'Espace Client'), 

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Vous avez appuyé sur le bouton :',
            ),
            Text(
              // Affichage de l'état actuel
              '$_compteur',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      // Bouton flottant pour déclencher la modification de l'état
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementerCompteur, // Appel de la méthode qui change l'état
        tooltip: 'Incrémenter',
        child: const Icon(Icons.add),
      ),
    );
  }
}