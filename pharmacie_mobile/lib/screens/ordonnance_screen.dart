// lib/screens/ordonnance_screen.dart : le patient photographie (ou choisit) son ordonnance

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/photos.dart';

class OrdonnanceScreen extends StatefulWidget {
  const OrdonnanceScreen({super.key});

  @override
  State<OrdonnanceScreen> createState() => _OrdonnanceScreenState();
}

class _OrdonnanceScreenState extends State<OrdonnanceScreen> {
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _ordonnances = [];
  bool _chargement = true;
  bool _envoi = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final liste = await AuthService.mesOrdonnances();
    if (!mounted) return;
    setState(() {
      _ordonnances = liste;
      _chargement = false;
    });
  }

  void _message(String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: erreur ? AppColors.rouge : AppColors.vertFonce,
      content: Text(texte),
    ));
  }

  Future<void> _prendre(ImageSource source) async {
    XFile? photo;
    try {
      photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1800,
        preferredCameraDevice: CameraDevice.rear,
      );
    } catch (e) {
      _message(
          source == ImageSource.camera
              ? 'Impossible d\'ouvrir l\'appareil photo sur cet appareil. Choisissez plutôt une image de la galerie.'
              : 'Impossible d\'ouvrir la galerie.',
          erreur: true);
      return;
    }
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!mounted) return;

    final note = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _Apercu(bytes: bytes)),
    );
    if (note == null) return;

    setState(() => _envoi = true);
    final nom = photo.name.isNotEmpty ? photo.name : 'ordonnance.jpg';
    final err = await AuthService.envoyerOrdonnance(bytes, nom, note);
    if (!mounted) return;
    setState(() => _envoi = false);
    if (err == null) {
      _message('Ordonnance envoyée au pharmacien');
      _charger();
    } else {
      _message(err, erreur: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(
        title: const Text('Mes ordonnances'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _charger),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _carteEnvoi(),
            const SizedBox(height: 22),
            const Text('Historique',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.texte)),
            const SizedBox(height: 10),
            if (_chargement)
              const Padding(
                padding: EdgeInsets.all(30),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_ordonnances.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: decoCarte(),
                child: const Column(children: [
                  Icon(Icons.description_outlined, size: 44, color: AppColors.gris),
                  SizedBox(height: 8),
                  Text('Aucune ordonnance envoyée pour le moment',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.gris)),
                ]),
              )
            else
              ..._ordonnances.map((o) => _ligne(o as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }

  Widget _carteEnvoi() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.vertFonce, AppColors.vert],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: ombreCarte(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Envoyer une ordonnance',
              style: TextStyle(
                  color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          const Text(
            'Photo nette, texte lisible, en entier. Le pharmacien la vérifie avant la commande.',
            style: TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 16),
          if (_envoi)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: CircularProgressIndicator(color: Colors.white),
              ),
            )
          else
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _prendre(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Prendre en photo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.vertFonce,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _prendre(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galerie'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ]),
        ],
      ),
    );
  }

  Widget _ligne(Map<String, dynamic> o) {
    final id = int.tryParse(o['id'].toString()) ?? 0;
    final motif = o['motif_rejet'];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: decoCarte(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ZoomOrdonnanceScreen(
                    id: id, titre: o['numero_ordonnance'].toString()),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ImageOrdonnance(id: id, hauteur: 72, largeur: 72),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(o['numero_ordonnance'].toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                  StatutOrdonnance(o['statut'].toString()),
                ]),
                const SizedBox(height: 4),
                Text('Envoyée le ${o['date_envoi']}',
                    style: const TextStyle(fontSize: 12, color: AppColors.gris)),
                if (motif != null) ...[
                  const SizedBox(height: 6),
                  Text('Motif du rejet : $motif',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.rouge)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Apercu extends StatefulWidget {
  final Uint8List bytes;
  const _Apercu({required this.bytes});

  @override
  State<_Apercu> createState() => _ApercuState();
}

class _ApercuState extends State<_Apercu> {
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(title: const Text('Vérifier la photo')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: InteractiveViewer(
                  child: Image.memory(widget.bytes, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note pour le pharmacien',
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Reprendre'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, _noteCtrl.text),
                  icon: const Icon(Icons.send),
                  label: const Text('Envoyer au pharmacien'),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}