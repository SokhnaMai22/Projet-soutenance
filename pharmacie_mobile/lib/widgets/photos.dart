// lib/widgets/photos.dart : logo, photos (médicaments, pharmaciens, ordonnances)
// Si une photo n'existe pas encore dans assets/, un visuel de remplacement propre s'affiche.

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

/// Logo de l'application, dessiné en code (aucune image à copier)
/// Logo de l'application (assets/logo.png)
class LogoPharma extends StatelessWidget {
  final double taille;
  const LogoPharma({super.key, this.taille = 44});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(taille * 0.24),
      child: Image.asset(
        'assets/logo.png',
        width: taille,
        height: taille,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: taille,
          height: taille,
          color: AppColors.vert,
          child: Icon(Icons.local_pharmacy, color: Colors.white, size: taille * 0.6),
        ),
      ),
    );
  }
}

/// Photo d'un médicament (assets/medicaments/<nom>.jpg, .png, .jpeg ou .webp)
class PhotoMedicament extends StatelessWidget {
  final String? fichier;
  final double? hauteur;
  final double rayon;
  final bool contenir; // true : photo entière sur fond blanc (packshot)

  const PhotoMedicament(
      {super.key, this.fichier, this.hauteur, this.rayon = 14, this.contenir = false});

  static const _extensions = ['jpg', 'png', 'jpeg', 'webp'];

  // Essaie chaque extension dans l'application (assets) ; sinon charge la photo depuis le serveur ;
  // si rien n'existe, affiche le visuel de remplacement
  Widget _essayer(List<String> chemins, Widget remplacement, String? urlReseau) {
    if (chemins.isEmpty) {
      if (urlReseau == null) return remplacement;
      return Image.network(
        urlReseau,
        height: hauteur,
        width: double.infinity,
        fit: contenir ? BoxFit.contain : BoxFit.cover,
        errorBuilder: (_, __, ___) => remplacement,
      );
    }
    return Image.asset(
      chemins.first,
      height: hauteur,
      cacheWidth: 500,
      width: double.infinity,
      fit: contenir ? BoxFit.contain : BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          _essayer(chemins.sublist(1), remplacement, urlReseau),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remplacement = Container(
      height: hauteur,
      width: double.infinity,
      color: AppColors.vertClair,
      child: const Center(
        child: Icon(Icons.medication_rounded, size: 44, color: AppColors.vert),
      ),
    );

    String? base;
    String? urlReseau;
    if (fichier != null && fichier!.isNotEmpty) {
      base = fichier!.replaceAll(RegExp(r'\.[A-Za-z0-9]+$'), '');
      urlReseau = '${AuthService.baseUrl}/images/medicaments/$fichier';
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(rayon),
      child: base == null
          ? remplacement
          : _essayer(
              _extensions.map((e) => 'assets/medicaments/$base.$e').toList(),
              remplacement,
              urlReseau,
            ),
    );
  }
}
/// Photo ronde d'une personne : pharmacien (assets/pharmacies) ou profil (assets/profils)
class PhotoRonde extends StatelessWidget {
  final String? dossier; // 'pharmacies' ou 'profils'
  final String? fichier;
  final String nom; // pour les initiales si la photo manque
  final double taille;
  final Color fond;

  const PhotoRonde({
    super.key,
    required this.dossier,
    required this.fichier,
    required this.nom,
    this.taille = 48,
    this.fond = AppColors.vertClair,
  });

  String get _initiales {
    final mots = nom.replaceAll(RegExp(r'^(Dr|Pr)\.?\s+'), '').trim().split(RegExp(r'\s+'));
    if (mots.isEmpty || mots.first.isEmpty) return '?';
    final a = mots.first[0];
    final b = mots.length > 1 ? mots.last[0] : '';
    return (a + b).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final initiales = Container(
      width: taille,
      height: taille,
      alignment: Alignment.center,
      color: fond,
      child: Text(
        _initiales,
        style: TextStyle(
          fontSize: taille * 0.36,
          fontWeight: FontWeight.w800,
          color: AppColors.vertFonce,
        ),
      ),
    );

    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: ombreCarte(),
      ),
      child: ClipOval(
        child: (dossier == null || fichier == null || fichier!.isEmpty)
            ? initiales
            : Image.asset(
                'assets/$dossier/$fichier',
                width: taille,
                height: taille,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => initiales,
              ),
      ),
    );
  }
}

/// Image d'une ordonnance : téléchargée avec le jeton de connexion (accès protégé)
class ImageOrdonnance extends StatelessWidget {
  final int id;
  final double? hauteur;
  final double? largeur;
  final BoxFit fit;

  const ImageOrdonnance({
    super.key,
    required this.id,
    this.hauteur,
    this.largeur,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final vide = Container(
      height: hauteur,
      width: largeur,
      color: AppColors.vertClair,
      child: const Icon(Icons.description_outlined, color: AppColors.vert),
    );
    return Image.network(
      ApiService.urlImageOrdonnance(id),
      headers: {
        'Authorization': 'Bearer ${AuthService.token}',
        'Accept': 'image/*',
      },
      height: hauteur,
      width: largeur,
      fit: fit,
      loadingBuilder: (c, child, progress) => progress == null
          ? child
          : Container(
              height: hauteur,
              width: largeur,
              color: AppColors.vertClair,
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
      errorBuilder: (_, __, ___) => vide,
    );
  }
}

/// Plein écran avec zoom (pincer pour agrandir) : lecture de l'ordonnance par le pharmacien
class ZoomOrdonnanceScreen extends StatelessWidget {
  final int id;
  final String titre;

  const ZoomOrdonnanceScreen({super.key, required this.id, required this.titre});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(titre),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: ImageOrdonnance(id: id, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// Pastille de statut d'une ordonnance
class StatutOrdonnance extends StatelessWidget {
  final String statut;
  const StatutOrdonnance(this.statut, {super.key});

  @override
  Widget build(BuildContext context) {
    late final String texte;
    late final Color fond;
    late final Color encre;
    late final IconData icone;
    switch (statut) {
      case 'VALIDEE':
        texte = 'Validée';
        fond = AppColors.vertClair;
        encre = AppColors.vertFonce;
        icone = Icons.check_circle;
        break;
      case 'REJETEE':
        texte = 'Rejetée';
        fond = AppColors.rougeClair;
        encre = AppColors.rouge;
        icone = Icons.cancel;
        break;
      default:
        texte = 'En attente';
        fond = AppColors.orangeClair;
        encre = AppColors.orange;
        icone = Icons.hourglass_top_rounded;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icone, size: 14, color: encre),
        const SizedBox(width: 4),
        Text(texte,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: encre)),
      ]),
    );
  }
}