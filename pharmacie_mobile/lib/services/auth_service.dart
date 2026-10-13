import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class AuthService {
  // Edge : 127.0.0.1 | Émulateur Android : 10.0.2.2 | Vrai téléphone : IP du PC
  static const String baseUrl = 'http://127.0.0.1:8000';

  static String? token;
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

  static Future<String?> register(
      String name, String email, String password) async {
    return _appel(
        '/api/register', {'name': name, 'email': email, 'password': password});
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
  static Future<bool> validerOrdonnance(int id) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/ordonnances/$id/valider'),
        headers: headers);
    return res.statusCode == 200;
  }

  // Pharmacien : rejeter avec motif
  static Future<bool> rejeterOrdonnance(int id, String motif) async {
    final res = await http.post(
        Uri.parse('$baseUrl/api/ordonnances/$id/rejeter'),
        headers: headers,
        body: jsonEncode({'motif': motif}));
    return res.statusCode == 200;
  }

  static void deconnexion() {
    token = null;
    user = null;
  }
}