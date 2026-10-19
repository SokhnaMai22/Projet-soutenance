// lib/models/medicament.dart

class Medicament {
  final String id;
  final String nom;
  final String description;
  final double prix; // Prix en FCFA
  final bool necessiteOrdonnance; // Règle clé : ordonnance obligatoire ou non
  final String forme; // Ex: Comprimé, Sirop, Gélule
  final String dosage; // Ex: 500mg, 1000mg
  final String pharmacieNom; // Nom de la pharmacie qui l'a en stock
  final int stockDisponible;
  final String? image; // Nom du fichier dans assets/medicaments/
  final String categorie;
  final String pharmacieQuartier;
  final String pharmacienNom;
  final String? pharmaciePhoto; // Nom du fichier dans assets/pharmacies/

  Medicament({
    required this.id,
    required this.nom,
    required this.description,
    required this.prix,
    required this.necessiteOrdonnance,
    required this.forme,
    required this.dosage,
    required this.pharmacieNom,
    required this.stockDisponible,
    this.image,
    this.categorie = 'Autres',
    this.pharmacieQuartier = '',
    this.pharmacienNom = '',
    this.pharmaciePhoto,
  });

  factory Medicament.fromJson(Map<String, dynamic> j) {
    return Medicament(
      id: j['id'].toString(),
      nom: (j['nom'] ?? '') as String,
      description: (j['description'] ?? '') as String,
      prix: double.tryParse(j['prix'].toString()) ?? 0,
      necessiteOrdonnance:
          j['necessite_ordonnance'] == 1 || j['necessite_ordonnance'] == true,
      forme: (j['forme'] ?? '') as String,
      dosage: (j['dosage'] ?? '') as String,
      pharmacieNom: (j['pharmacie_nom'] ?? '') as String,
      stockDisponible: int.tryParse(j['stock'].toString()) ?? 0,
      image: j['image'] as String?,
      categorie: (j['categorie'] ?? 'Autres') as String,
      pharmacieQuartier: (j['pharmacie_quartier'] ?? '') as String,
      pharmacienNom: (j['pharmacien_nom'] ?? '') as String,
      pharmaciePhoto: j['pharmacie_photo'] as String?,
    );
  }
}