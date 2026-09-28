// lib/screens/catalogue_screen.dart

import 'package:flutter/material.dart';
import '../models/medicament.dart';
import '../services/catalogue_service.dart';
import '../widgets/medicament_card.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  // Liste affichée (filtrée selon la recherche)
  List<Medicament> _medicamentsAffiches = [];
  String _filtreActuel = 'TOUS'; // TOUS, LIBRE, ORDONNANCE
  final TextEditingController _rechercheController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _medicamentsAffiches = CatalogueService.medicaments;
  }

  // Filtrer selon la recherche et le type
  void _appliquerFiltres(String texte) {
    List<Medicament> resultats = CatalogueService.rechercher(texte);

    if (_filtreActuel == 'LIBRE') {
      resultats = resultats.where((m) => !m.necessiteOrdonnance).toList();
    } else if (_filtreActuel == 'ORDONNANCE') {
      resultats = resultats.where((m) => m.necessiteOrdonnance).toList();
    }

    setState(() {
      _medicamentsAffiches = resultats;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PharmaSanté Sénégal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Trouvez vos médicaments & pharmacies',
              style: TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            tooltip: 'Panier',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Le panier sera branché à la prochaine étape !')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Barre de recherche
          Container(
            color: Colors.teal.shade700,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _rechercheController,
              onChanged: _appliquerFiltres,
              decoration: InputDecoration(
                hintText: 'Rechercher un médicament (ex: Paracétamol)...',
                prefixIcon: const Icon(Icons.search, color: Colors.teal),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Filtres (Chips)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                _buildFiltreChip('Tous', 'TOUS'),
                const SizedBox(width: 8),
                _buildFiltreChip('Vente libre', 'LIBRE'),
                const SizedBox(width: 8),
                _buildFiltreChip('Sur ordonnance', 'ORDONNANCE'),
              ],
            ),
          ),

          // 3. Bannière "Envoyer une Ordonnance"
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.teal.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.camera_alt_outlined, color: Colors.teal.shade800, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vous avez une ordonnance ?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade900,
                        ),
                      ),
                      const Text(
                        'Photographiez-la pour validation par le pharmacien.',
                        style: TextStyle(fontSize: 12, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Écran ordonnance bientôt connecté !')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  child: const Text('Envoyer'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Liste des médicaments
          Expanded(
            child: _medicamentsAffiches.isEmpty
                ? const Center(
                    child: Text(
                      'Aucun médicament trouvé.',
                      style: TextStyle(fontSize: 15, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _medicamentsAffiches.length,
                    itemBuilder: (context, index) {
                      final medicament = _medicamentsAffiches[index];
                      return MedicamentCard(
                        medicament: medicament,
                        onTap: () {
                          _afficherDetailsMedicament(context, medicament);
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // Widget des boutons filtres
  Widget _buildFiltreChip(String label, String valeur) {
    final estSelectionne = _filtreActuel == valeur;
    return ChoiceChip(
      label: Text(label),
      selected: estSelectionne,
      selectedColor: Colors.teal.shade700,
      labelStyle: TextStyle(
        color: estSelectionne ? Colors.white : Colors.black87,
        fontWeight: estSelectionne ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _filtreActuel = valeur;
          });
          _appliquerFiltres(_rechercheController.text);
        }
      },
    );
  }

  // Boîte de dialogue simple pour voir le détail
  void _afficherDetailsMedicament(BuildContext context, Medicament medicament) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                medicament.nom,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                medicament.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 12),
              Text(
                'Pharmacie : ${medicament.pharmacieNom}',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey),
              ),
              const SizedBox(height: 6),
              Text(
                'Stock disponible : ${medicament.stockDisponible} boîtes',
                style: TextStyle(
                  color: medicament.stockDisponible > 0 ? Colors.green.shade700 : Colors.red,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${medicament.prix.toInt()} FCFA',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Ajouter au panier'),
                    onPressed: () {
                      Navigator.pop(context);
                      if (medicament.necessiteOrdonnance) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            backgroundColor: Colors.orange,
                            content: Text(
                              'Règle de gestion : Ce médicament nécessite une ordonnance validée !',
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: Colors.green,
                            content: Text('${medicament.nom} ajouté au panier !'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}