// lib/services/catalogue_service.dart

import '../models/medicament.dart';
import 'api_service.dart';

class Pharmacie {
  final int id;
  final String nom;
  final String quartier;
  final String pharmacienNom;
  final String? photo;
  Pharmacie(this.id, this.nom, this.quartier, this.pharmacienNom, this.photo);
}

class CatalogueService {
  static List<Medicament> medicaments = [];
  static List<Pharmacie> pharmacies = [];

  /// Charge le catalogue depuis le serveur. Retourne null si tout va bien,
  /// sinon un message d'erreur (on n'invente plus de données locales :
  /// les identifiants doivent correspondre à la base pour que la commande soit valide).
  static Future<String?> charger() async {
    try {
      final meds = await ApiService.medicaments();
      medicaments = meds
          .map((e) => Medicament.fromJson(e as Map<String, dynamic>))
          .toList();
      final phs = await ApiService.pharmacies();
      pharmacies = phs
          .map((e) => Pharmacie(
                int.tryParse(e['id'].toString()) ?? 0,
                (e['nom'] ?? '') as String,
                (e['quartier'] ?? '') as String,
                (e['pharmacien_nom'] ?? '') as String,
                e['photo'] as String?,
              ))
          .toList();
      return null;
    } catch (e) {
      return 'Impossible de charger le catalogue. Vérifiez la connexion au serveur.';
    }
  }

  static List<String> get categories {
    final set = <String>{};
    for (final m in medicaments) {
      set.add(m.categorie);
    }
    final liste = set.toList()..sort();
    return liste;
  }
}