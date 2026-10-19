// lib/widgets/medicament_card.dart : carte produit (photo, nom, prix, ordonnance, ajout rapide)

import 'package:flutter/material.dart';
import '../models/medicament.dart';
import '../theme/app_theme.dart';
import 'photos.dart';

class MedicamentCard extends StatelessWidget {
  final Medicament medicament;
  final VoidCallback onTap;
  final VoidCallback onAjouter;

  const MedicamentCard({
    super.key,
    required this.medicament,
    required this.onTap,
    required this.onAjouter,
  });

  @override
  Widget build(BuildContext context) {
    final m = medicament;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: decoCarte(rayon: 20),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo du produit sur fond blanc (packshot)
            AspectRatio(
              aspectRatio: 1.15,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(10),
                    child: PhotoMedicament(fichier: m.image, rayon: 8, contenir: true),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _Badge(ordonnance: m.necessiteOrdonnance),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: AppColors.texte,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${m.forme} · ${m.dosage}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11.5, color: AppColors.gris),
                    ),
                                        const SizedBox(height: 3),
                    Text(
                      m.pharmacieNom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.vertFonce),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${m.prix.toInt()} FCFA',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.vertFonce,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 36,
                      child: TextButton(
                        onPressed: onAjouter,
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.vertClair,
                          foregroundColor: AppColors.vertFonce,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Text(
                          'Ajouter au panier',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final bool ordonnance;
  const _Badge({required this.ordonnance});

  @override
  Widget build(BuildContext context) {
    final fond = ordonnance ? AppColors.orange : AppColors.vert;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: fond,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          ordonnance ? Icons.assignment_outlined : Icons.check_circle_outline,
          size: 12,
          color: Colors.white,
        ),
        const SizedBox(width: 4),
        Text(
          ordonnance ? 'Ordonnance' : 'Vente libre',
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ]),
    );
  }
}