// lib/theme/app_theme.dart : identité visuelle « vert santé »

import 'package:flutter/material.dart';

class AppColors {
  static const Color vert = Color(0xFF0E8F63);
  static const Color vertFonce = Color(0xFF0A6B4A);
  static const Color vertClair = Color(0xFFE3F3EC);
  static const Color fond = Color(0xFFF4F8F6);
  static const Color texte = Color(0xFF14302A);
  static const Color gris = Color(0xFF6B7F79);
  static const Color orange = Color(0xFFD97706);
  static const Color orangeClair = Color(0xFFFFF3DD);
  static const Color rouge = Color(0xFFD64545);
  static const Color rougeClair = Color(0xFFFDE8E8);
  static const Color bleu = Color(0xFF2563EB);
  static const Color bleuClair = Color(0xFFE3ECFF);
}

ThemeData buildAppTheme() {
  final base = ColorScheme.fromSeed(
    seedColor: AppColors.vert,
    primary: AppColors.vert,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: base,
    scaffoldBackgroundColor: AppColors.fond,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.vertFonce,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.vert,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    ),
       navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.vertClair,
      height: 68,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// Ombre douce commune à toutes les cartes
List<BoxShadow> ombreCarte() => [
      BoxShadow(
        color: const Color(0xFF0A3D2E).withValues(alpha: 0.08),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
    ];

BoxDecoration decoCarte({Color couleur = Colors.white, double rayon = 18}) =>
    BoxDecoration(
      color: couleur,
      borderRadius: BorderRadius.circular(rayon),
      boxShadow: ombreCarte(),
    );