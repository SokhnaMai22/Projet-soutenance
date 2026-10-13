// lib/models/ordonnance.dart

enum StatutOrdonnance {
  enAttente,
  validee,
  rejetee,
}

class Ordonnance {
  final String id;
  final String patientNom;
  final String pharmacieNom;
  final DateTime dateEnvoi;
  StatutOrdonnance statut;
  final String? motifRejet;
  final String? notePatient;
  final String imagePath;

  Ordonnance({
    required this.id,
    required this.patientNom,
    required this.pharmacieNom,
    required this.dateEnvoi,
    this.statut = StatutOrdonnance.enAttente,
    this.motifRejet,
    this.notePatient,
    required this.imagePath,
  });

  String get statutTexte {
    switch (statut) {
      case StatutOrdonnance.enAttente:
        return 'En attente de validation';
      case StatutOrdonnance.validee:
        return 'Validée par le pharmacien';
      case StatutOrdonnance.rejetee:
        return 'Rejetée';
    }
  }
}