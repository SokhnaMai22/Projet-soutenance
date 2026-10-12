import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<Position> positionActuelle() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Activez la localisation de votre appareil');
    }
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      throw Exception('Permission de localisation refusée');
    }
    return Geolocator.getCurrentPosition();
  }

  // Transforme des coordonnées en adresse lisible (OpenStreetMap / Nominatim)
  static Future<String> adresseDepuis(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=jsonv2&lat=$lat&lon=$lng&accept-language=fr',
      );
      final res = await http.get(uri);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['display_name'] ?? 'Adresse inconnue';
      }
    } catch (_) {}
    return 'Lat ${lat.toStringAsFixed(5)}, Lng ${lng.toStringAsFixed(5)}';
  }
}