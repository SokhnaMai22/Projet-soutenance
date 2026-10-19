// lib/screens/commandes_pharmacien_tab.dart : le pharmacien prépare les commandes et les marque "prêtes"

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class CommandesPharmacienTab extends StatefulWidget {
  const CommandesPharmacienTab({super.key});

  @override
  State<CommandesPharmacienTab> createState() => _CommandesPharmacienTabState();
}

class _CommandesPharmacienTabState extends State<CommandesPharmacienTab> {
  List<dynamic> _commandes = [];
  bool _chargement = true;
  String? _erreur;
  Timer? _timer;

  static const _aPreparer = ['CREEE', 'PAYEE', 'EN_PREPARATION'];

  @override
  void initState() {
    super.initState();
    _charger();
    _timer = Timer.periodic(
        const Duration(seconds: 10), (_) => _charger(silencieux: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) setState(() => _chargement = true);
    try {
      final liste = await ApiService.commandesPharmacien();
      if (!mounted) return;
      setState(() {
        _commandes = liste;
        _erreur = null;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted || silencieux) return;
      setState(() {
        _erreur = 'Impossible de joindre le serveur';
        _chargement = false;
      });
    }
  }

  Future<void> _marquerPrete(int id) async {
    final erreur = await ApiService.marquerPrete(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: erreur == null ? AppColors.vertFonce : AppColors.rouge,
      content: Text(erreur ?? 'Commande prête : un livreur peut la récupérer'),
    ));
    if (erreur == null) _charger(silencieux: true);
  }

  int _compte(List<String> statuts) =>
      _commandes.where((c) => statuts.contains(c['statut'].toString())).length;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.fond,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 8, 4),
            child: Row(children: [
              const Expanded(
                child: Text('Commandes à préparer',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              IconButton(
                  icon: const Icon(Icons.refresh), onPressed: _charger),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(children: [
              _compteur('À préparer', _compte(_aPreparer), AppColors.orange),
              const SizedBox(width: 10),
              _compteur('Prêtes', _compte(['PRETE']), AppColors.vertFonce),
              const SizedBox(width: 10),
              _compteur('En livraison', _compte(['EN_LIVRAISON']), AppColors.bleu),
            ]),
          ),
          Expanded(child: _contenu()),
        ],
      ),
    );
  }

  Widget _compteur(String titre, int n, Color couleur) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: decoCarte(),
        child: Column(children: [
          Text('$n',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: couleur)),
          Text(titre,
              style: const TextStyle(fontSize: 11.5, color: AppColors.gris)),
        ]),
      ),
    );
  }

  Widget _contenu() {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erreur != null) {
      return Center(
          child: Text(_erreur!, style: const TextStyle(color: AppColors.gris)));
    }
    if (_commandes.isEmpty) {
      return const Center(
          child: Text('Aucune commande pour le moment',
              style: TextStyle(color: AppColors.gris)));
    }
    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        itemCount: _commandes.length,
        itemBuilder: (context, i) =>
            _carte(_commandes[i] as Map<String, dynamic>),
      ),
    );
  }

  Widget _pastille(String statut) {
    String texte;
    Color fond;
    Color couleur;
    if (statut == 'PRETE') {
      texte = 'Prête';
      fond = AppColors.vertClair;
      couleur = AppColors.vertFonce;
    } else if (statut == 'EN_LIVRAISON') {
      texte = 'En livraison';
      fond = AppColors.bleuClair;
      couleur = AppColors.bleu;
    } else {
      texte = 'À préparer';
      fond = AppColors.orangeClair;
      couleur = AppColors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: fond, borderRadius: BorderRadius.circular(10)),
      child: Text(texte,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: couleur)),
    );
  }

  Widget _carte(Map<String, dynamic> c) {
    final id = int.tryParse(c['id'].toString()) ?? 0;
    final statut = c['statut'].toString();
    final lignes = (c['lignes'] as List<dynamic>?) ?? [];
    final montant = c['montant_total'].toString().split('.').first;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: decoCarte(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text('Commande ${c['numero_commande']}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            _pastille(statut),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.person_outline, size: 16, color: AppColors.gris),
            const SizedBox(width: 4),
            Text('${c['patient_nom']}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.gris)),
          ]),
          const SizedBox(height: 8),
          for (final l in lignes)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text('${l['quantite']} × ${l['nom']}',
                  style: const TextStyle(fontSize: 13.5)),
            ),
          const SizedBox(height: 8),
          Text('$montant FCFA',
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: AppColors.vertFonce)),
          if (_aPreparer.contains(statut)) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _marquerPrete(id),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Marquer prête'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}