// lib/screens/livreur_screen.dart : espace livreur relié au serveur
// Règle : une seule livraison en cours à la fois (contrôlée côté serveur).

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/photos.dart';
import 'login_screen.dart';

class LivreurScreen extends StatefulWidget {
  const LivreurScreen({super.key});

  @override
  State<LivreurScreen> createState() => _LivreurScreenState();
}

class _LivreurScreenState extends State<LivreurScreen> {
  Map<String, dynamic>? _data;
  bool _chargement = true;
  String? _erreur;
  bool _occupe = false;
  Timer? _minuteur;

  @override
  void initState() {
    super.initState();
    _charger();
    // Rafraîchit toutes les 10 s pour voir les nouvelles commandes
    _minuteur = Timer.periodic(const Duration(seconds: 10), (_) => _charger(silencieux: true));
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) setState(() => _chargement = true);
    try {
      final d = await ApiService.livraisons();
      if (!mounted) return;
      setState(() {
        _data = d;
        _erreur = null;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silencieux) {
        setState(() {
          _erreur = 'Impossible de joindre le serveur';
          _chargement = false;
        });
      }
    }
  }

  void _message(String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: erreur ? AppColors.rouge : AppColors.vertFonce,
      content: Text(texte),
    ));
  }

  Future<void> _accepter(int id) async {
    setState(() => _occupe = true);
    final err = await ApiService.accepterLivraison(id);
    if (!mounted) return;
    setState(() => _occupe = false);
    _message(err ?? 'Livraison acceptée. Bonne route !', erreur: err != null);
    _charger(silencieux: true);
  }

  Future<void> _terminer(int id) async {
    setState(() => _occupe = true);
    final err = await ApiService.terminerLivraison(id);
    if (!mounted) return;
    setState(() => _occupe = false);
    _message(err ?? 'Commande marquée comme livrée', erreur: err != null);
    _charger(silencieux: true);
  }

  @override
  Widget build(BuildContext context) {
    final nom = AuthService.user?['name']?.toString() ?? 'Livreur';
    final enCours = _data?['en_cours'] as Map<String, dynamic>?;
    final dispo = (_data?['disponibles'] as List<dynamic>?) ?? [];
    final histo = (_data?['historique'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: RefreshIndicator(
        onRefresh: _charger,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _entete(nom)),
            if (_chargement)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erreur != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.gris),
                    const SizedBox(height: 10),
                    Text(_erreur!, style: const TextStyle(color: AppColors.gris)),
                    const SizedBox(height: 12),
                    ElevatedButton(onPressed: _charger, child: const Text('Réessayer')),
                  ]),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _titre('Livraison en cours'),
                    if (enCours != null)
                      _carteCourse(enCours, enCours: true)
                    else
                      _vide('Aucune livraison en cours.\nAcceptez une course ci-dessous.'),
                    const SizedBox(height: 22),
                    _titre('Courses disponibles (${dispo.length})'),
                    if (dispo.isEmpty)
                      _vide('Aucune commande à livrer pour le moment.')
                    else
                      ...dispo.map((c) => _carteCourse(c as Map<String, dynamic>,
                          bloque: enCours != null)),
                    if (histo.isNotEmpty) ...[
                      const SizedBox(height: 22),
                      _titre('Historique récent'),
                      ...histo.map((c) => _ligneHistorique(c as Map<String, dynamic>)),
                    ],
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _entete(String nom) {
    final livrees = _data?['total_livrees'] ?? 0;
    final gains = (_data?['gains'] ?? 0).toString().split('.').first;
    return Container(
      padding: EdgeInsets.fromLTRB(
          18, MediaQuery.of(context).padding.top + 14, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.vertFonce, AppColors.vert],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(children: [
        Row(children: [
          PhotoRonde(dossier: 'profils', fichier: 'livreur.jpg', nom: nom, taille: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nom,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                const Row(children: [
                  Icon(Icons.circle, size: 9, color: Color(0xFF7CF5B8)),
                  SizedBox(width: 5),
                  Text('En service',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ]),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              AuthService.deconnexion();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ]),
        const SizedBox(height: 16),
        Row(children: [
          _stat('Livraisons faites', '$livrees'),
          const SizedBox(width: 10),
          _stat('Gains', '$gains FCFA'),
        ]),
      ]),
    );
  }

  Widget _stat(String titre, String valeur) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Text(valeur,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.vertFonce)),
          Text(titre,
              style: const TextStyle(fontSize: 11.5, color: AppColors.gris)),
        ]),
      ),
    );
  }

  Widget _titre(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.texte)),
      );

  Widget _vide(String t) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: decoCarte(),
        child: Text(t,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.gris, height: 1.4)),
      );

  Widget _carteCourse(Map<String, dynamic> c,
      {bool enCours = false, bool bloque = false}) {
    final id = int.tryParse(c['id'].toString()) ?? 0;
    final lignes = (c['lignes'] as List<dynamic>?) ?? [];
    final tel = c['patient_telephone'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: ombreCarte(),
        border: enCours ? Border.all(color: AppColors.vert, width: 1.6) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Commande ${c['numero_commande']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 15.5)),
            ),
            Text('${c['frais_livraison'].toString().split('.').first} FCFA',
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.vertFonce)),
          ]),
          const Divider(height: 22),
          _etape(Icons.storefront, AppColors.vert, 'Récupérer à',
              '${c['pharmacie_nom']} · ${c['pharmacie_quartier']}'),
          const SizedBox(height: 10),
          _etape(Icons.location_on, AppColors.rouge, 'Livrer à',
              '${c['patient_nom']}\n${c['adresse_livraison']}'
              '${tel != null ? '\nTél. $tel' : ''}'),
          if (lignes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: lignes
                  .map((l) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.vertClair,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('${l['quantite']} × ${l['nom']}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.vertFonce)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: enCours
                ? ElevatedButton.icon(
                    onPressed: _occupe ? null : () => _terminer(id),
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmer la livraison au patient'),
                  )
                : ElevatedButton.icon(
                    onPressed: (_occupe || bloque) ? null : () => _accepter(id),
                    icon: const Icon(Icons.two_wheeler),
                    label: Text(bloque
                        ? 'Terminez votre livraison en cours'
                        : 'Accepter cette course'),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _etape(IconData icone, Color couleur, String titre, String texte) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: couleur.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icone, size: 19, color: couleur),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre,
                  style: const TextStyle(fontSize: 11.5, color: AppColors.gris)),
              Text(texte,
                  style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.texte)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ligneHistorique(Map<String, dynamic> c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: decoCarte(rayon: 14),
      child: Row(children: [
        const Icon(Icons.check_circle, color: AppColors.vert),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(c['numero_commande'].toString(),
                  style: const TextStyle(fontWeight: FontWeight.w800)),
              Text('Livrée à ${c['patient_nom']}',
                  style: const TextStyle(fontSize: 12, color: AppColors.gris)),
            ],
          ),
        ),
        Text('${c['frais_livraison'].toString().split('.').first} FCFA',
            style: const TextStyle(color: AppColors.vertFonce, fontSize: 12.5)),
      ]),
    );
  }
}