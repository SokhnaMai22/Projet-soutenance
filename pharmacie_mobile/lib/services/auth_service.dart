import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AuthService {
  // Edge : 127.0.0.1 | Émulateur Android : 10.0.2.2 | Vrai téléphone : IP du PC
  static const String baseUrl = String.fromEnvironment('API_URL',
      defaultValue: 'http://187.126.0.25:8082');  static String? token;
  static Map<String, dynamic>? user;

  static String get role => (user?['role'] ?? '') as String;
  static Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<String?> login(String email, String password) async {
    return _appel('/api/login', {'email': email, 'password': password});
  }

    static Future<String?> register(Map<String, String> champs) async {
    return _appel('/api/register', champs);
  }

  // Retourne null si tout va bien, sinon un message d'erreur
  static Future<String?> _appel(
      String chemin, Map<String, String> corps) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl$chemin'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json'
        },
        body: jsonEncode(corps),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 || res.statusCode == 201) {
        token = data['token'];
        user = data['user'];
        return null;
      }
      return data['message']?.toString() ?? 'Erreur ${res.statusCode}';
    } catch (e) {
      return 'Impossible de joindre le serveur';
    }
  }

  // Patient : envoyer une ordonnance (photo + note)
  static Future<String?> envoyerOrdonnance(
      Uint8List bytes, String nomFichier, String note) async {
    try {
      final req = http.MultipartRequest(
          'POST', Uri.parse('$baseUrl/api/ordonnances'));
      req.headers['Accept'] = 'application/json';
      req.headers['Authorization'] = 'Bearer $token';
      req.fields['note'] = note;
      req.files.add(
          http.MultipartFile.fromBytes('image', bytes, filename: nomFichier));
      final res = await req.send();
      if (res.statusCode == 201) return null;
      return 'Erreur ${res.statusCode}';
    } catch (e) {
      return 'Impossible de joindre le serveur';
    }
  }

  // Patient : lire ses ordonnances
  static Future<List<dynamic>> mesOrdonnances() async {
    final res = await http.get(Uri.parse('$baseUrl/api/mes-ordonnances'),
        headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    return [];
  }

  // Pharmacien : toutes les ordonnances
  static Future<List<dynamic>> toutesOrdonnances() async {
    final res = await http.get(Uri.parse('$baseUrl/api/ordonnances'),
        headers: headers);
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    return [];
  }

  // Pharmacien : valider
    // Pharmacien : valider en indiquant les médicaments autorisés
  // Retourne null si OK, sinon le message d'erreur
  static Future<String?> validerOrdonnance(
      int id, List<Map<String, dynamic>> medicaments) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/ordonnances/$id/valider'),
        headers: headers,
        body: jsonEncode({'medicaments': medicaments}),
      );
      if (res.statusCode == 200) return null;
      final data = jsonDecode(res.body);
      return data['message']?.toString() ?? 'Erreur ${res.statusCode}';
    } catch (e) {
      return 'Impossible de joindre le serveur';
    }
  }
  // Pharmacien : rejeter avec motif
  static Future<bool> rejeterOrdonnance(int id, String motif) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/ordonnances/$id/rejeter'),
        headers: headers,
        body: jsonEncode({'motif': motif}));
    return res.statusCode == 200;
  }
    // Patient : vérifier la règle « ordonnance validée » avant le paiement.
  // Retourne null si la commande est autorisée, sinon le message du serveur.
    static Future<String?> verifierCommande(
      List<Map<String, dynamic>> lignes) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/commande/verifier'),
        headers: headers,
        body: jsonEncode({'lignes': lignes}),
      );
      if (res.statusCode == 200) return null;
      final data = jsonDecode(res.body);
      return data['message']?.toString() ?? 'Erreur ${res.statusCode}';
    } catch (e) {
      return 'Impossible de joindre le serveur';
    }
  }

  // Patient : enregistrer la commande en base.
  // Retourne null si la commande est créée, sinon un message d'erreur.
  static Future<String?> creerCommande(
      String adresse, List<Map<String, dynamic>> lignes) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/commande'),
        headers: headers,
        body: jsonEncode({'adresse_livraison': adresse, 'lignes': lignes}),
      );
      if (res.statusCode == 201) return null;
      final data = jsonDecode(res.body);
      return data['message']?.toString() ?? 'Erreur ${res.statusCode}';
    } catch (e) {
      return 'Impossible de joindre le serveur';
    }
  }

    // Pharmacien : ajouter un médicament (avec photo facultative).
  // Retourne null si tout va bien, sinon un message d'erreur.
  static Future<String?> ajouterMedicament(
      Map<String, String> champs, Uint8List? bytes, String? nomFichier) async {
    try {
      final req =
          http.MultipartRequest('POST', Uri.parse('$baseUrl/api/medicaments'));
      req.headers['Accept'] = 'application/json';
      req.headers['Authorization'] = 'Bearer $token';
      req.fields.addAll(champs);
      if (bytes != null) {
        req.files.add(http.MultipartFile.fromBytes('image', bytes,
            filename: nomFichier ?? 'photo.jpg'));
      }
      final res = await http.Response.fromStream(await req.send());
      if (res.statusCode == 201) return null;
      final data = jsonDecode(res.body);
      return data['message']?.toString() ?? 'Erreur ${res.statusCode}';
    } catch (e)   {
      return 'Impossible de joindre le serveur';
    }
  }

  static void deconnexion() {
    token = null;
    user = null;
  }
}