// lib/screens/panier_screen.dart

import 'package:flutter/material.dart';
import '../models/panier.dart';
import '../services/auth_service.dart';
import 'paiement_screen.dart';
import 'choisir_adresse_screen.dart';
import 'ordonnance_screen.dart';

class PanierScreen extends StatefulWidget {
  const PanierScreen({super.key});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  final double fraisLivraison = 1000.0; // 1 000 FCFA

  // Adresse de livraison choisie sur la carte
  String? _adresseLivraison;
  double? _latitude;
  double? _longitude;

  Future<void> _choisirAdresse() async {
    final res = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const ChoisirAdresseScreen()),
    );
    if (res != null) {
      setState(() {
        _adresseLivraison = res['adresse'] as String;
        _latitude = res['latitude'] as double;
        _longitude = res['longitude'] as double;
      });
    }
  }

  // Vérifie la règle « ordonnance validée » auprès du serveur,
  // puis ouvre l'écran de paiement.
  Future<void> _passerAuPaiement(double totalGeneral) async {
    if (_adresseLivraison == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choisissez d\'abord votre adresse de livraison'),
        ),
      );
      return;
    }

        final lignes = PanierService.articles.map<Map<String, dynamic>>((a) {
      return {
        'medicament_id': int.tryParse(a.medicament.id) ?? 0,
        'quantite': a.quantite,
      };
    }).toList();

    final erreur = await AuthService.verifierCommande(lignes);
    if (!mounted) return;

    if (erreur != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.orange.shade800,
          persist: false,
          duration: const Duration(seconds: 6),
          content: Text(erreur),
          action: SnackBarAction(
            label: 'Mes ordonnances',
            textColor: Colors.white,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrdonnanceScreen()),
              );
            },
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaiementScreen(
          montantTotal: totalGeneral,
          adresseLivraison: _adresseLivraison,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final articles = PanierService.articles;
    final double totalMedicaments = PanierService.montantTotal;
    final double totalGeneral =
        totalMedicaments > 0 ? totalMedicaments + fraisLivraison : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Mon Panier'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: articles.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text(
                    'Votre panier est vide',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ajoutez des médicaments depuis le catalogue.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Parcourir le catalogue'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: articles.length,
                    itemBuilder: (context, index) {
                      final item = articles[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 45,
                                height: 45,
                                decoration: BoxDecoration(
                                  color: Colors.teal.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(Icons.medication,
                                    color: Colors.teal.shade700),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.medicament.nom,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                    Text(
                                      '${item.medicament.prix.toInt()} FCFA / unité',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Total : ${item.total.toInt()} FCFA',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                        Icons.remove_circle_outline,
                                        color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        PanierService.diminuer(item.medicament);
                                      });
                                    },
                                  ),
                                  Text(
                                    '${item.quantite}',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline,
                                        color: Colors.teal),
                                    onPressed: () {
                                      setState(() {
                                        PanierService.ajouter(item.medicament);
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Carte « Adresse de livraison »
                Card(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading:
                        Icon(Icons.location_on, color: Colors.teal.shade700),
                    title: const Text('Adresse de livraison',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      _adresseLivraison ?? 'Aucune adresse choisie',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: TextButton(
                      onPressed: _choisirAdresse,
                      child: Text(
                          _adresseLivraison == null ? 'Choisir' : 'Modifier'),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sous-total médicaments :',
                              style: TextStyle(color: Colors.grey)),
                          Text('${totalMedicaments.toInt()} FCFA',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Frais de livraison (Dakar) :',
                              style: TextStyle(color: Colors.grey)),
                          Text('${fraisLivraison.toInt()} FCFA',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total à payer :',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(
                            '${totalGeneral.toInt()} FCFA',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal.shade800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.payment),
                          label: const Text('Passer au paiement',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _passerAuPaiement(totalGeneral),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}