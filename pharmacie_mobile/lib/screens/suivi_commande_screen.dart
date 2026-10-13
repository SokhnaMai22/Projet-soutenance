// lib/screens/suivi_commande_screen.dart

import 'package:flutter/material.dart';

class SuiviCommandeScreen extends StatefulWidget {
  final String numeroCommande;
  final double montantTotal;

  const SuiviCommandeScreen({
    super.key,
    this.numeroCommande = 'CMD-2026-084',
    this.montantTotal = 4000.0,
  });

  @override
  State<SuiviCommandeScreen> createState() => _SuiviCommandeScreenState();
}

class _SuiviCommandeScreenState extends State<SuiviCommandeScreen> {
  // Étape actuelle : 0=Reçue, 1=Payée, 2=Préparée, 3=En cours de livraison, 4=Livrée
  int _etapeActuelle = 2; // Par défaut : en préparation à la pharmacie

  final List<Map<String, dynamic>> _etapes = [
    {
      'titre': 'Commande confirmée',
      'description': 'Votre commande a été enregistrée avec succès.',
      'icone': Icons.receipt_long,
    },
    {
      'titre': 'Paiement Wave / OM validé',
      'description': 'Transaction sécurisée confirmée.',
      'icone': Icons.verified,
    },
    {
      'titre': 'Préparation en pharmacie',
      'description': 'Pharmacie Guigon prépare vos médicaments.',
      'icone': Icons.local_pharmacy,
    },
    {
      'titre': 'En cours de livraison',
      'description': 'Le livreur fait route vers votre adresse.',
      'icone': Icons.delivery_dining,
    },
    {
      'titre': 'Commande livrée',
      'description': 'Médicaments remis en main propre.',
      'icone': Icons.home,
    },
  ];

  void _avancerEtape() {
    setState(() {
      if (_etapeActuelle < _etapes.length - 1) {
        _etapeActuelle++;
      } else {
        _etapeActuelle = 0; // Recommencer la démo
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Suivi de Commande'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Carte résumé commande
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Commande #${widget.numeroCommande}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.teal),
                          ),
                          child: Text(
                            '${widget.montantTotal.toInt()} FCFA',
                            style: TextStyle(
                              color: Colors.teal.shade800,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    const Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.blueGrey),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Destination : Dakar, Médina Rue 22 x 15',
                            style: TextStyle(fontSize: 13, color: Colors.blueGrey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Coordonnées du livreur (Règle 2.1.4 : assignation au livreur)
            if (_etapeActuelle >= 3)
              Card(
                elevation: 2,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.blue.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade700,
                        child: const Icon(Icons.two_wheeler, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Livreur assigné : Ibrahima Sow',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Moto Jakarta • Arrivée estimée : ~15 min',
                              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        tooltip: 'Appeler',
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Appel du livreur : +221 77 987 65 43')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // 3. Timeline des étapes
            const Text(
              'Statut d\'acheminement :',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Column(
                  children: List.generate(_etapes.length, (index) {
                    final etape = _etapes[index];
                    final bool estPasse = index <= _etapeActuelle;
                    final bool estEnCours = index == _etapeActuelle;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rond de l'étape
                          Column(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: estPasse
                                      ? (estEnCours ? Colors.orange : Colors.teal.shade700)
                                      : Colors.grey.shade300,
                                ),
                                child: Icon(
                                  estPasse ? etape['icone'] : Icons.circle,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                              if (index < _etapes.length - 1)
                                Container(
                                  width: 2,
                                  height: 35,
                                  color: estPasse ? Colors.teal.shade700 : Colors.grey.shade300,
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Textes de l'étape
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  etape['titre'],
                                  style: TextStyle(
                                    fontWeight: estPasse ? FontWeight.bold : FontWeight.normal,
                                    color: estPasse ? Colors.black87 : Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  etape['description'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: estPasse ? Colors.black54 : Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 4. Bouton de démonstration pour le Jury
            Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fast_forward),
                label: const Text('Simuler l\'étape suivante (Démo Jury)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade700,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _avancerEtape,
              ),
            ),
          ],
        ),
      ),
    );
  }
}