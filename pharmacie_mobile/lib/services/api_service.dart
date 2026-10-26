// lib/services/api_service.dart : appels serveur ajoutés pour le catalogue, le livreur et le suivi.
// Utilise l'adresse (baseUrl) et le jeton déjà gérés par AuthService.

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class ApiService {
  static String urlImageOrdonnance(int id) =>
      '${AuthService.baseUrl}/api/ordonnances/$id/image';

  static Future<List<dynamic>> _liste(String chemin) async {
    final res = await http
        .get(Uri.parse('${AuthService.baseUrl}$chemin'),
            headers: AuthService.headers)
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Erreur ${res.statusCode}');
  }

  // Appel public (sans jeton) : évite la demande préliminaire du navigateur
  static Future<List<dynamic>> _listePublique(String chemin) async {
    final res = await http
        .get(Uri.parse('${AuthService.baseUrl}$chemin'),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception('Erreur ${res.statusCode}');
  }

  // Catalogue
  static Future<List<dynamic>> medicaments() =>
      _listePublique('/api/medicaments');
  static Future<List<dynamic>> pharmacies() =>
      _listePublique('/api/pharmacies');

  // Patient : ses commandes avec statut
  static Future<List<dynamic>> mesCommandes() => _liste('/api/mes-commandes');

  // Livreur : tout l'écran en un appel
  static Future<Map<String, dynamic>> livraisons() async {
    final res = await http
        .get(Uri.parse('${AuthService.baseUrl}/api/livraisons'),
            headers: AuthService.headers)
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('Erreur ${res.statusCode}');
  }

  // Retourne null si OK, sinon le message du serveur
  static Future<String?> _action(String chemin) async {
    try {
      final res = await http.post(
        Uri.parse('${AuthService.baseUrl}$chemin'),
        headers: AuthService.headers,
      );
      if (res.statusCode == 200) return null;
      final data = jsonDecode(res.body);
      return data['message']?.toString() ?? 'Erreur ${res.statusCode}';
    } catch (e) {
      return 'Impossible de joindre le serveur';
    }
  }

  // Pharmacien : commandes à préparer
  static Future<List<dynamic>> commandesPharmacien() =>
      _liste('/api/pharmacien/commandes');
  static Future<String?> marquerPrete(int id) =>
      _action('/api/pharmacien/commandes/$id/prete');

  static Future<String?> accepterLivraison(int id) =>
      _action('/api/livraisons/$id/accepter');
  static Future<String?> terminerLivraison(int id) =>
      _action('/api/livraisons/$id/terminer');
}