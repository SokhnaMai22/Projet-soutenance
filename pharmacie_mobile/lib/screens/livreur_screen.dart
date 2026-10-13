// lib/screens/livreur_screen.dart

import 'package:flutter/material.dart';

class LivreurScreen extends StatefulWidget {
  const LivreurScreen({super.key});

  @override
  State<LivreurScreen> createState() => _LivreurScreenState();
}

class _LivreurScreenState extends State<LivreurScreen> {
  // Statut de la course active : ASSIGNEE -> EN_ROUTE -> LIVREE
  String _statutCourse = 'EN_ROUTE'; // EN_ROUTE vers le client

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Espace Livreur - PharmaSanté'),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profil du Livreur
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: Colors.blueGrey.shade100,
                      child: const Icon(Icons.two_wheeler, size: 32, color: Colors.blueGrey),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ibrahima Sow',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Moto Jakarta • Dakar Centre',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: Colors.green),
                          SizedBox(width: 4),
                          Text('En service', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 2. Statistiques de la journée
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text('Courses du jour', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            _statutCourse == 'LIVREE' ? '4' : '3',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Card(
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: [
                          const Text('Gains livraison', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text(
                            _statutCourse == 'LIVREE' ? '4 000 FCFA' : '3 000 FCFA',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Règle de gestion 2.1.4 : Une seule livraison en cours à la fois
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Livraison en cours (1 max) :',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Text('Règle 2.1.4 active', style: TextStyle(fontSize: 10, color: Colors.orange)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (_statutCourse != 'LIVREE')
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Commande #CMD-2026-084',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Payé par Wave ✅',
                              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Point de départ (Pharmacie)
                      const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.store, color: Colors.teal, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pharmacie Guigon (Dakar Plateau)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Colis récupéré et prêt', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Point d'arrivée (Patient)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Mamadou Diop', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('Dakar, Médina Rue 22 x 15', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.phone, color: Colors.green),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Appel du patient : +221 77 123 45 67')),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Bouton d'action pour le livreur
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'Confirmer la livraison au patient',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          onPressed: () {
                            setState(() {
                              _statutCourse = 'LIVREE';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                backgroundColor: Colors.green,
                                content: Text('Commande marquée comme LIVRÉE avec succès !'),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    Icon(Icons.check_circle, size: 48, color: Colors.green.shade700),
                    const SizedBox(height: 8),
                    const Text(
                      'Toutes les livraisons sont terminées !',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Vous êtes disponible pour recevoir une nouvelle course.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _statutCourse = 'EN_ROUTE'; // Pour réinitialiser la démo
                        });
                      },
                      child: const Text('Réinitialiser la démo jury'),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // 4. Historique récent
            const Text(
              'Historique récent :',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Commande #CMD-2026-081', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: const Text('Livrée à Point E • 1 000 FCFA'),
                trailing: Text('14:30', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}