// lib/screens/ajouter_medicament_tab.dart : formulaire d'ajout de médicament (pharmacien)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class AjouterMedicamentTab extends StatefulWidget {
  const AjouterMedicamentTab({super.key});

  @override
  State<AjouterMedicamentTab> createState() => _AjouterMedicamentTabState();
}

class _AjouterMedicamentTabState extends State<AjouterMedicamentTab> {
  final _nom = TextEditingController();
  final _description = TextEditingController();
  final _forme = TextEditingController();
  final _dosage = TextEditingController();
  final _prix = TextEditingController();
  final _quantite = TextEditingController();
  final _categorie = TextEditingController();
  bool _surOrdonnance = false;
  bool _envoi = false;
  Uint8List? _bytes;
  String? _nomFichier;

  void _message(String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: erreur ? AppColors.rouge : AppColors.vertFonce,
      content: Text(texte),
    ));
  }

  Future<void> _choisirPhoto() async {
    final img = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (img == null) return;
    final b = await img.readAsBytes();
    setState(() {
      _bytes = b;
      _nomFichier = img.name;
    });
  }

  void _vider() {
    for (final c in [_nom, _description, _forme, _dosage, _prix, _quantite, _categorie]) {
      c.clear();
    }
    setState(() {
      _surOrdonnance = false;
      _bytes = null;
      _nomFichier = null;
    });
  }

  Future<void> _enregistrer() async {
    final prix = double.tryParse(_prix.text.trim().replaceAll(',', '.'));
    final quantite = int.tryParse(_quantite.text.trim());
    if (_nom.text.trim().isEmpty ||
        _forme.text.trim().isEmpty ||
        _dosage.text.trim().isEmpty) {
      _message('Nom, forme et dosage sont obligatoires', erreur: true);
      return;
    }
    if (prix == null || quantite == null) {
      _message('Le prix et la quantité doivent être des nombres', erreur: true);
      return;
    }
    setState(() => _envoi = true);
    final erreur = await AuthService.ajouterMedicament({
      'nom': _nom.text.trim(),
      'description': _description.text.trim(),
      'forme': _forme.text.trim(),
      'dosage': _dosage.text.trim(),
      'prix': prix.toString(),
      'quantite': quantite.toString(),
      'necessite_ordonnance': _surOrdonnance ? '1' : '0',
      if (_categorie.text.trim().isNotEmpty) 'categorie': _categorie.text.trim(),
    }, _bytes, _nomFichier);
    if (!mounted) return;
    setState(() => _envoi = false);
    if (erreur == null) {
      _message('Médicament ajouté au catalogue');
      _vider();
    } else {
      _message(erreur, erreur: true);
    }
  }

  Widget _champ(String label, TextEditingController c,
      {TextInputType? type, int lignes = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLines: lignes,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text('Ajouter un médicament',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            _champ('Nom *', _nom),
            _champ('Description', _description, lignes: 2),
            Row(children: [
              Expanded(child: _champ('Forme *', _forme)),
              const SizedBox(width: 10),
              Expanded(child: _champ('Dosage * (500 mg)', _dosage)),
            ]),
            Row(children: [
              Expanded(
                  child: _champ('Prix (FCFA) *', _prix,
                      type: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(
                  child: _champ('Quantité en stock *', _quantite,
                      type: TextInputType.number)),
            ]),
            _champ('Catégorie', _categorie),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vendu sur ordonnance'),
              value: _surOrdonnance,
              onChanged: (v) => setState(() => _surOrdonnance = v),
            ),
            const SizedBox(height: 6),
            if (_bytes != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(_bytes!, height: 160, fit: BoxFit.cover),
              ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _choisirPhoto,
              icon: const Icon(Icons.photo_library_outlined),
              label: Text(_bytes == null ? 'Choisir une photo' : 'Changer la photo'),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _envoi ? null : _enregistrer,
              icon: _envoi
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Enregistrer le médicament'),
            ),
          ],
        ),
      ),
    );
  }
}