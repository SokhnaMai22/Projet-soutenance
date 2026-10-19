import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'catalogue_screen.dart';
import 'livreur_screen.dart';
import 'pharmacien_screen.dart';
import 'admin_screen.dart';
import '../widgets/photos.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _prenom = TextEditingController();
  final _nom = TextEditingController();
  final _email = TextEditingController();
  final _telephone = TextEditingController();
  final _mdp = TextEditingController();
  final _mdp2 = TextEditingController();

  bool _inscription = false;
  bool _loading = false;
  bool _voirMdp = false;
  bool _voirMdp2 = false;
  bool _cgu = false;
  String? _erreur;

  @override
  void dispose() {
    for (final c in [_prenom, _nom, _email, _telephone, _mdp, _mdp2]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------- Validations ----------
  String? _requis(String? v, String label) =>
      (v == null || v.trim().isEmpty) ? '$label obligatoire' : null;

  String? _validerEmail(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email obligatoire';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim())) {
      return 'Email invalide';
    }
    return null;
  }

  String? _validerTelephone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Téléphone obligatoire';
    final n = v.replaceAll(RegExp(r'\s'), '');
    if (!RegExp(r'^(\+?221)?(7[05678]|33)\d{7}$').hasMatch(n)) {
      return 'Numéro invalide (ex : 77 123 45 67)';
    }
    return null;
  }

  String? _validerMdp(String? v) {
    if (v == null || v.isEmpty) return 'Mot de passe obligatoire';
    if (!_inscription) return null;

    if (v.length < 8) return 'Au moins 8 caractères';

    if (!RegExp(r'[A-Za-z]').hasMatch(v) ||
        !RegExp(r'\d').hasMatch(v)) {
      return 'Doit contenir des lettres et des chiffres';
    }

    return null;
  }

  // Force du mot de passe : 0 à 4
  int _force(String v) {
    var f = 0;

    if (v.length >= 8) f++;
    if (RegExp(r'[A-Z]').hasMatch(v) &&
        RegExp(r'[a-z]').hasMatch(v)) {
      f++;
    }
    if (RegExp(r'\d').hasMatch(v)) f++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(v)) f++;

    return f;
  }

  Future<void> _valider() async {
    if (!_formKey.currentState!.validate()) return;

    if (_inscription && !_cgu) {
      setState(() =>
          _erreur = 'Vous devez accepter les conditions d\'utilisation');
      return;
    }

    setState(() {
      _loading = true;
      _erreur = null;
    });

    final err = _inscription
        ? await AuthService.register({
            'prenom': _prenom.text.trim(),
            'nom': _nom.text.trim(),
            'email': _email.text.trim(),
            'telephone': _telephone.text.trim(),
            'password': _mdp.text,
            'password_confirmation': _mdp2.text,
          })
        : await AuthService.login(
            _email.text.trim(),
            _mdp.text,
          );

    if (!mounted) return;

    setState(() => _loading = false);

    if (err != null) {
      setState(() => _erreur = err);
      return;
    }

    Widget ecran;

    switch (AuthService.role) {
      case 'livreur':
        ecran = const LivreurScreen();
        break;

      case 'pharmacien':
        ecran = const PharmacienScreen();
        break;
              case 'admin':
        ecran = const AdminScreen();
        break;

      default:
        ecran = const CatalogueScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ecran),
    );
  }

  // ---------- Widgets utilitaires ----------
  Widget _champ(
    TextEditingController c,
    String label, {
    IconData? icone,
    TextInputType? type,
    String? Function(String?)? validator,
    TextCapitalization cap = TextCapitalization.none,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          keyboardType: type,
          textCapitalization: cap,
          validator: validator ?? (v) => _requis(v, label),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icone != null ? Icon(icone) : null,
            border: const OutlineInputBorder(),
          ),
        ),
      );

  Widget _champMdp(
    TextEditingController c,
    String label,
    bool visible,
    VoidCallback toggle, {
    String? Function(String?)? validator,
    ValueChanged<String>? onChanged,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: c,
          obscureText: !visible,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.lock_outline),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: visible ? 'Masquer' : 'Afficher',
              icon: Icon(
                visible
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: toggle,
            ),
          ),
        ),
      );

  Widget _barreForce() {
    final f = _force(_mdp.text);

    const couleurs = [
      Colors.red,
      Colors.red,
      Colors.orange,
      Colors.lightGreen,
      Colors.green
    ];

    const textes = [
      'Très faible',
      'Faible',
      'Moyen',
      'Bon',
      'Excellent'
    ];

    if (_mdp.text.isEmpty) {
      return const SizedBox(height: 4);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: f / 4,
              color: couleurs[f],
              backgroundColor: Colors.grey.shade300,
              minHeight: 6,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            textes[f],
            style: TextStyle(
              color: couleurs[f],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const LogoPharma(taille: 96),

                  const SizedBox(height: 8),

                  const Text(
                    'PharmaSanté Sénégal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _inscription
                        ? 'Créer votre compte'
                        : 'Connexion',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 20),

                  if (_inscription) ...[
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _champ(
                            _prenom,
                            'Prénom',
                            icone: Icons.person_outline,
                            cap: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _champ(
                            _nom,
                            'Nom',
                            cap: TextCapitalization.words,
                          ),
                        ),
                      ],
                    ),
                  ],

                  _champ(
                    _email,
                    'Email',
                    icone: Icons.email_outlined,
                    type: TextInputType.emailAddress,
                    validator: _validerEmail,
                  ),

                  if (_inscription)
                    _champ(
                      _telephone,
                      'Téléphone',
                      icone: Icons.phone_outlined,
                      type: TextInputType.phone,
                      validator: _validerTelephone,
                    ),

                  _champMdp(
                    _mdp,
                    'Mot de passe',
                    _voirMdp,
                    () => setState(
                        () => _voirMdp = !_voirMdp),
                    validator: _validerMdp,
                    onChanged: (_) {
                      if (_inscription) {
                        setState(() {});
                      }
                    },
                  ),

                  if (_inscription) ...[
                    _barreForce(),

                    _champMdp(
                      _mdp2,
                      'Confirmer le mot de passe',
                      _voirMdp2,
                      () => setState(
                          () => _voirMdp2 = !_voirMdp2),
                      validator: (v) =>
                          (v != _mdp.text)
                              ? 'Les mots de passe ne correspondent pas'
                              : null,
                    ),

                    CheckboxListTile(
                      value: _cgu,
                      onChanged: (v) => setState(
                          () => _cgu = v ?? false),
                      controlAffinity:
                          ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: const Text(
                        'J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],

                  if (_erreur != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _erreur!,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed:
                          _loading ? null : _valider,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.teal.shade700,
                        foregroundColor: Colors.white,
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              _inscription
                                  ? 'Créer mon compte'
                                  : 'Se connecter',
                            ),
                    ),
                  ),

                  TextButton(
                    onPressed: () => setState(() {
                      _inscription = !_inscription;
                      _erreur = null;
                      _formKey.currentState?.reset();
                    }),
                    child: Text(
                      _inscription
                          ? 'J\'ai déjà un compte'
                          : 'Pas de compte ? S\'inscrire',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}