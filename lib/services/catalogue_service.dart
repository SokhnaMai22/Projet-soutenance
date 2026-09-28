// lib/services/catalogue_service.dart

import '../models/medicament.dart';

class CatalogueService {
  // Liste de médicaments de démonstration
  static final List<Medicament> medicaments = [
    Medicament(
      id: '1',
      nom: 'Paracétamol (Doliprane)',
      description: 'Indiqué en cas de douleur et/ou fièvre (maux de tête, états grippaux).',
      prix: 1500, // 1 500 FCFA
      necessiteOrdonnance: false, // Vente libre
      forme: 'Comprimé',
      dosage: '1000 mg',
      pharmacieNom: 'Pharmacie Guigon (Dakar Plateau)',
      stockDisponible: 25,
    ),
    Medicament(
      id: '2',
      nom: 'Amoxicilline',
      description: 'Antibiotique utilisé pour traiter diverses infections bactériennes.',
      prix: 3200, // 3 200 FCFA
      necessiteOrdonnance: true, // Ordonnance OBLIGATOIRE
      forme: 'Gélule',
      dosage: '500 mg',
      pharmacieNom: 'Pharmacie Cheikh Anta Diop (Fann)',
      stockDisponible: 12,
    ),
    Medicament(
      id: '3',
      nom: 'Vitamine C 1000',
      description: 'Complément pour réduire la fatigue et renforcer le système immunitaire.',
      prix: 2500, // 2 500 FCFA
      necessiteOrdonnance: false, // Vente libre
      forme: 'Comprimé effervescent',
      dosage: '1000 mg',
      pharmacieNom: 'Pharmacie de la Nation',
      stockDisponible: 40,
    ),
    Medicament(
      id: '4',
      nom: 'Artéméther / Luméfantrine (Coartem)',
      description: 'Traitement curatif des accès palustres (Paludisme).',
      prix: 4500, // 4 500 FCFA
      necessiteOrdonnance: true, // Ordonnance OBLIGATOIRE
      forme: 'Comprimé',
      dosage: '20/120 mg',
      pharmacieNom: 'Pharmacie Guigon (Dakar Plateau)',
      stockDisponible: 8,
    ),
    Medicament(
      id: '5',
      nom: 'Spasfon (Phloroglucinol)',
      description: 'Traitement des douleurs spasmodiques du tube digestif et des voies urinaires.',
      prix: 2800, // 2 800 FCFA
      necessiteOrdonnance: false, // Vente libre
      forme: 'Comprimé',
      dosage: '80 mg',
      pharmacieNom: 'Pharmacie du Point E',
      stockDisponible: 19,
    ),
  ];

  // Fonction pour rechercher par nom de médicament
  static List<Medicament> rechercher(String texte) {
    if (texte.isEmpty) return medicaments;
    return medicaments
        .where((m) => m.nom.toLowerCase().contains(texte.toLowerCase()))
        .toList();
  }
}