// lib/screens/suivi_commande_screen.dart : suivi réel des commandes du patient

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SuiviCommandeScreen extends StatefulWidget {
  // Paramètres conservés pour compatibilité avec l'écran de paiement
  final String? numeroCommande;
  final double? montantTotal;

  const SuiviCommandeScreen({super.key, this.numeroCommande, this.montantTotal});

  @override
  State<SuiviCommandeScreen> createState() => _SuiviCommandeScreenState();
}

class _SuiviCommandeScreenState extends State<SuiviCommandeScreen> {
  List<dynamic> _commandes = [];
  bool _chargement = true;
  String? _erreur;
  Timer? _minuteur;

  static const _etapes = [
    ['Commande enregistrée', 'Votre commande est transmise à la pharmacie.', Icons.receipt_long],
    ['Préparation en pharmacie', 'Le pharmacien prépare vos médicaments.', Icons.local_pharmacy],
    ['En cours de livraison', 'Le livreur est en route vers vous.', Icons.delivery_dining],
    ['Commande livrée', 'Médicaments remis en main propre.', Icons.home],
  ];

  @override
  void initState() {
    super.initState();
    _charger();
    _minuteur = Timer.periodic(const Duration(seconds: 8), (_) => _charger(silencieux: true));
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  Future<void> _charger({bool silencieux = false}) async {
    if (!silencieux) setState(() => _chargement = true);
    try {
      final l = await ApiService.mesCommandes();
      if (!mounted) return;
      setState(() {
        _commandes = l;
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

  int _etape(String statut) {
    switch (statut) {
      case 'EN_PREPARATION':
      case 'PRETE':
        return 1;
      case 'EN_LIVRAISON':
        return 2;
      case 'LIVREE':
        return 3;
      default:
        return 0; // CREEE, PAYEE
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        title: const Text('Suivi de mes commandes'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _charger),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: _chargement
            ? ListView(children: const [
                SizedBox(height: 200),
                Center(child: CircularProgressIndicator()),
              ])
            : _erreur != null
                ? ListView(children: [
                    const SizedBox(height: 160),
                    const Icon(Icons.wifi_off_rounded, size: 52, color: AppColors.gris),
                    const SizedBox(height: 10),
                    Center(
                        child: Text(_erreur!,
                            style: const TextStyle(color: AppColors.gris))),
                  ])
                : _commandes.isEmpty
                    ? ListView(children: const [
                        SizedBox(height: 160),
                        Icon(Icons.shopping_bag_outlined,
                            size: 56, color: AppColors.gris),
                        SizedBox(height: 10),
                        Center(
                          child: Text('Vous n\'avez pas encore de commande',
                              style: TextStyle(color: AppColors.gris)),
                        ),
                      ])
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _commandes.length,
                        itemBuilder: (context, i) =>
                            _carte(_commandes[i] as Map<String, dynamic>, i == 0),
                      ),
      ),
    );
  }

  Widget _carte(Map<String, dynamic> c, bool premiere) {
    final statut = c['statut'].toString();
    final annulee = statut == 'ANNULEE';
    final etape = _etape(statut);
    final lignes = (c['lignes'] as List<dynamic>?) ?? [];
    final livreur = c['livreur_nom'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
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
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.vertClair,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('${c['montant_total'].toString().split('.').first} FCFA',
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      color: AppColors.vertFonce)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.location_on_outlined, size: 16, color: AppColors.gris),
            const SizedBox(width: 4),
            Expanded(
              child: Text('${c['adresse_livraison']}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.gris)),
            ),
          ]),
          if (lignes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(lignes.map((l) => '${l['quantite']} × ${l['nom']}').join('  ·  '),
                style: const TextStyle(fontSize: 12.5, color: AppColors.texte)),
          ],
          const Divider(height: 24),
          if (annulee)
            const Text('Commande annulée',
                style: TextStyle(
                    color: AppColors.rouge, fontWeight: FontWeight.w800))
          else
            ...List.generate(_etapes.length, (i) {
              final fait = i <= etape;
              final courant = i == etape;
              final derniere = i == _etapes.length - 1;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Column(children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: fait ? AppColors.vert : Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_etapes[i][2] as IconData,
                            size: 18,
                            color: fait ? Colors.white : Colors.grey),
                      ),
                      if (!derniere)
                        Expanded(
                          child: Container(
                            width: 3,
                            color: i < etape
                                ? AppColors.vert
                                : Colors.grey.shade200,
                          ),
                        ),
                    ]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_etapes[i][0] as String,
                                style: TextStyle(
                                    fontWeight: courant
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: fait
                                        ? AppColors.texte
                                        : Colors.grey)),
                            if (courant)
                              Text(
                                i == 2 && livreur != null
                                    ? 'Livreur : $livreur'
                                                                        : (i == 1 && statut == 'PRETE')
                                        ? 'Commande prête, en attente d\'un livreur'
                                        : _etapes[i][1] as String,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.gris),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}