import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

// Espace administrateur : création et liste des comptes pharmacien et livreur.
// (L'inscription publique ne crée que des patients.)
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<dynamic> _comptes = [];
  bool _chargement = true;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = false;
    });
    try {
      final l = await ApiService.comptes();
      if (!mounted) return;
      setState(() {
        _comptes = l;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = true;
      });
    }
  }

  void _message(String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: erreur ? Colors.red.shade700 : Colors.teal.shade800,
      content: Text(texte),
    ));
  }

  Widget _champ(TextEditingController c, String label,
      {TextInputType? type, bool cache = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: type,
        obscureText: cache,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Future<void> _creerCompte() async {
    final prenom = TextEditingController();
    final nom = TextEditingController();
    final email = TextEditingController();
    final tel = TextEditingController();
    final mdp = TextEditingController();
    String role = 'pharmacien';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Créer un compte'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButton<String>(
                isExpanded: true,
                value: role,
                items: const [
                  DropdownMenuItem(value: 'pharmacien', child: Text('Pharmacien')),
                  DropdownMenuItem(value: 'livreur', child: Text('Livreur')),
                ],
                onChanged: (v) => setD(() => role = v ?? 'pharmacien'),
              ),
              _champ(prenom, 'Prénom'),
              _champ(nom, 'Nom'),
              _champ(email, 'Email', type: TextInputType.emailAddress),
              _champ(tel, 'Téléphone (77 123 45 67)', type: TextInputType.phone),
              _champ(mdp, 'Mot de passe (8 caractères, lettres et chiffres)',
                  cache: true),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Créer')),
          ],
        ),
      ),
    );
    final corps = {
      'prenom': prenom.text.trim(),
      'nom': nom.text.trim(),
      'email': email.text.trim(),
      'telephone': tel.text.trim(),
      'password': mdp.text,
      'role': role,
    };
    for (final c in [prenom, nom, email, tel, mdp]) {
      c.dispose();
    }
    if (ok != true) return;
    if (corps['prenom'] == '' ||
        corps['nom'] == '' ||
        corps['email'] == '' ||
        corps['telephone'] == '' ||
        corps['password'] == '') {
      _message('Tous les champs sont obligatoires', erreur: true);
      return;
    }
    final err = await ApiService.creerCompte(corps);
    if (!mounted) return;
    _message(err ?? 'Compte créé', erreur: err != null);
    if (err == null) _charger();
  }

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _creerCompte,
        icon: const Icon(Icons.person_add),
        label: const Text('Créer un compte'),
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            const Text('Comptes pharmaciens et livreurs',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            if (_chargement)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()))
            else if (_erreur)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                      child: Text(
                          'Impossible de charger les comptes.\nTirez vers le bas pour réessayer.',
                          textAlign: TextAlign.center)))
            else if (_comptes.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                      child: Text(
                          'Aucun compte pour le moment.\nAppuyez sur « Créer un compte ».',
                          textAlign: TextAlign.center)))
            else
              ..._comptes.map((c) => Card(
                    child: ListTile(
                      leading: Icon(
                          c['role'] == 'pharmacien'
                              ? Icons.local_pharmacy_outlined
                              : Icons.delivery_dining,
                          color: Colors.teal.shade800),
                      title: Text('${c['name']}'),
                      subtitle: Text(
                          '${c['role'] == 'pharmacien' ? 'Pharmacien' : 'Livreur'} · ${c['email']}'),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}