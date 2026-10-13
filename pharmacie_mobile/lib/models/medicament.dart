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
  final String? imageUrl; // Lien vers l'image du médicament

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
    this.imageUrl,
  });
}