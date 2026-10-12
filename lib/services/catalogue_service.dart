// lib/services/catalogue_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/medicament.dart';

class CatalogueService {
  // URL de votre API Laravel
  static const String apiUrl = 'http://127.0.0.1:8000/api/medicaments';

  // Liste en mémoire
  static List<Medicament> medicaments = _donneesSecours;

  // Données de secours locales (si le serveur est éteint)
  static final List<Medicament> _donneesSecours = [
    Medicament(
      id: '1',
      nom: 'Paracétamol (Doliprane)',
      description: 'Soulage les maux de tête et la fièvre.',
      prix: 1500,
      necessiteOrdonnance: false,
      forme: 'Comprimé',
      dosage: '1000 mg',
      pharmacieNom: 'Pharmacie Guigon (Dakar Plateau)',
      stockDisponible: 25,
    ),
    Medicament(
      id: '2',
      nom: 'Amoxicilline',
      description: 'Antibiotique à large spectre.',
      prix: 3200,
      necessiteOrdonnance: true,
      forme: 'Gélule',
      dosage: '500 mg',
      pharmacieNom: 'Pharmacie Cheikh Anta Diop (Fann)',
      stockDisponible: 12,
    ),
    Medicament(
      id: '3',
      nom: 'Vitamine C 1000',
      description: 'Complément pour réduire la fatigue.',
      prix: 2500,
      necessiteOrdonnance: false,
      forme: 'Comprimé effervescent',
      dosage: '1000 mg',
      pharmacieNom: 'Pharmacie de la Nation',
      stockDisponible: 40,
    ),
  ];

  // Fonction asynchrone qui interroge Laravel / MySQL
  static Future<List<Medicament>> chargerDepuisApi() async {
    try {
      final response = await http.get(Uri.parse(apiUrl)).timeout(
        const Duration(seconds: 3),
      );

      if (response.statusCode == 200) {
        final List<dynamic> donneesJson = json.decode(response.body);

        medicaments = donneesJson.map((item) {
          return Medicament(
            id: item['id'].toString(),
            nom: item['nom'] ?? '',
            description: item['description'] ?? '',
            prix: double.tryParse(item['prix'].toString()) ?? 1500.0,
            necessiteOrdonnance: item['necessite_ordonnance'] == 1 || item['necessite_ordonnance'] == true,
            forme: item['forme'] ?? 'Comprimé',
            dosage: item['dosage'] ?? '500 mg',
            pharmacieNom: 'Pharmacie Guigon (Dakar Plateau)',
            stockDisponible: 20,
          );
        }).toList();

        return medicaments;
      }
    } catch (e) {
      // En cas de problème réseau, on utilise les données locales sans bloquer l'appli
      medicaments = _donneesSecours;
    }
    return medicaments;
  }

  // Recherche
  static List<Medicament> rechercher(String texte) {
    if (texte.isEmpty) return medicaments;
    return medicaments
        .where((m) => m.nom.toLowerCase().contains(texte.toLowerCase()))
        .toList();
  }
}