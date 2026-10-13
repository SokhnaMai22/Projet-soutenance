import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'catalogue_screen.dart';
import 'livreur_screen.dart';
import 'pharmacien_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _mdp = TextEditingController();
  bool _inscription = false;
  bool _loading = false;
  String? _erreur;

  Future<void> _valider() async {
    setState(() {
      _loading = true;
      _erreur = null;
    });
    final err = _inscription
        ? await AuthService.register(_nom.text.trim(), _email.text.trim(), _mdp.text)
        : await AuthService.login(_email.text.trim(), _mdp.text);
    if (!mounted) return;
    setState(() => _loading = false);

    if (err != null) {
      setState(() => _erreur = err);
      return;
    }

        // Redirection selon le rôle
    Widget ecran;
    switch (AuthService.role) {
      case 'livreur':
        ecran = const LivreurScreen();
        break;
      case 'pharmacien':
        ecran = const PharmacienScreen();
        break;
      default:
        ecran = const CatalogueScreen(); // patient (admin à venir)
    }
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => ecran));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            Icon(Icons.local_pharmacy, size: 70, color: Colors.teal.shade700),
            const SizedBox(height: 8),
            const Text('PharmaSanté Sénégal',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            if (_inscription) ...[
              TextField(
                controller: _nom,
                decoration: const InputDecoration(
                    labelText: 'Nom complet', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mdp,
              obscureText: true,
              decoration: const InputDecoration(
                  labelText: 'Mot de passe', border: OutlineInputBorder()),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 12),
              Text(_erreur!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _valider,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white),
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_inscription ? 'Créer mon compte' : 'Se connecter'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _inscription = !_inscription),
              child: Text(_inscription
                  ? 'J\'ai déjà un compte'
                  : 'Pas de compte ? S\'inscrire'),
            ),
          ]),
        ),
      ),
    );
  }
}