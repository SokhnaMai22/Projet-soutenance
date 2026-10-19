import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

// Espace administrateur : écran minimal, les fonctions d'administration
// (création des comptes pharmacien et livreur) sont à développer.
class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('Administrateur : ${AuthService.user?['name'] ?? ''}'),
        backgroundColor: Colors.teal.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Se déconnecter',
            onPressed: () {
              AuthService.deconnexion();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Espace administrateur\n\nLa gestion des comptes pharmacien et livreur sera disponible dans une prochaine version.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}