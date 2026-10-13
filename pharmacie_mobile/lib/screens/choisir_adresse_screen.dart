import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';

class ChoisirAdresseScreen extends StatefulWidget {
  const ChoisirAdresseScreen({super.key});

  @override
  State<ChoisirAdresseScreen> createState() => _ChoisirAdresseScreenState();
}

class _ChoisirAdresseScreenState extends State<ChoisirAdresseScreen> {
  final MapController _map = MapController();
  LatLng _point = const LatLng(14.6937, -17.4441); // Dakar par défaut
  String _adresse = 'Touchez la carte ou utilisez votre position';
  bool _loading = false;

  Future<void> _miseAJour(LatLng p) async {
    setState(() {
      _point = p;
      _adresse = 'Recherche de l\'adresse...';
    });
    final a = await LocationService.adresseDepuis(p.latitude, p.longitude);
    if (mounted) setState(() => _adresse = a);
  }

  Future<void> _maPosition() async {
    setState(() => _loading = true);
    try {
      final pos = await LocationService.positionActuelle();
      final p = LatLng(pos.latitude, pos.longitude);
      _map.move(p, 16);
      await _miseAJour(p);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adresse de livraison'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Expanded(
          child: FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _point,
              initialZoom: 13,
              onTap: (_, p) => _miseAJour(p),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.pharmacie_mobile',
              ),
              MarkerLayer(markers: [
                Marker(
                  point: _point,
                  width: 40,
                  height: 40,
                  child: const Icon(Icons.location_on,
                      color: Colors.red, size: 40),
                ),
              ]),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Text(_adresse, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _maPosition,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location),
                  label: const Text('Ma position'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'latitude': _point.latitude,
                    'longitude': _point.longitude,
                    'adresse': _adresse,
                  }),
                  child: const Text('Confirmer'),
                ),
              ),
            ]),
          ]),
        ),
      ]),
    );
  }
}