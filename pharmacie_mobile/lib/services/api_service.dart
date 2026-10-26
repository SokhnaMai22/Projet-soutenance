// lib/services/api_service.dart : appels serveur pour le catalogue, le livreur et le suivi.
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

  // ---------- Gestion du catalogue (pharmacien) ----------
  // (l'ajout d'un médicament avec photo est AuthService.ajouterMedicament)
  static Future<List<dynamic>> medicamentsGestion() =>
      _liste('/api/gestion/medicaments');

  // Envoie une requête JSON ; retourne null si le code attendu est reçu, sinon le message
  static Future<String?> _envoyerJson(
      String methode, String chemin, Map<String, dynamic>? corps, int attendu) async {
    try {
      final uri = Uri.parse('${AuthService.baseUrl}$chemin');
      final h = AuthService.headers;
      final b = corps == null ? null : jsonEncode(corps);
      late http.Response res;
      switch (methode) {
        case 'PUT':
          res = await http.put(uri, headers: h, body: b);
          break;
        case 'DELETE':
          res = await http.delete(uri, headers: h);
          break;
        default:
          res = await http.post(uri, headers: h, body: b);
      }
      if (res.statusCode == attendu) return null;
      final data = jsonDecode(res.body);
      return data['message']?.toString() ?? 'Erreur ${res.statusCode}';
    } catch (e) {
      return 'Impossible de joindre le serveur';
    }
  }

  static Future<String?> creerPharmacie(Map<String, dynamic> corps) =>
      _envoyerJson('POST', '/api/gestion/pharmacies', corps, 201);

  static Future<String?> definirStock(
          int pharmacieId, int medicamentId, int quantite) =>
      _envoyerJson(
          'POST',
          '/api/gestion/stocks',
          {
            'pharmacie_id': pharmacieId,
            'medicament_id': medicamentId,
            'quantite': quantite,
          },
          200);

  static Future<String?> modifierMedicament(
          int id, int prix, String description) =>
      _envoyerJson('PUT', '/api/gestion/medicaments/$id',
          {'prix': prix, 'description': description}, 200);

  static Future<String?> rendreIndisponible(int id) =>
      _envoyerJson('POST', '/api/gestion/medicaments/$id/indisponible', null, 200);

  static Future<String?> supprimerMedicament(int id) =>
      _envoyerJson('DELETE', '/api/gestion/medicaments/$id', null, 200);

  // ---------- Administrateur : comptes pharmacien / livreur ----------
  static Future<List<dynamic>> comptes() => _liste('/api/admin/comptes');

  static Future<String?> creerCompte(Map<String, dynamic> corps) =>
      _envoyerJson('POST', '/api/admin/comptes', corps, 201);
}