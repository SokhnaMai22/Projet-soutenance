import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';

class OrdonnanceScreen extends StatefulWidget {
  const OrdonnanceScreen({super.key});

  @override
  State<OrdonnanceScreen> createState() => _OrdonnanceScreenState();
}

class _OrdonnanceScreenState extends State<OrdonnanceScreen> {
  final ImagePicker _picker = ImagePicker();
  List<dynamic> _ordonnances = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final liste = await AuthService.mesOrdonnances();
    if (!mounted) return;
    setState(() {
      _ordonnances = liste;
      _loading = false;
    });
  }

  Future<void> _nouvelle() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Prendre une photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Choisir dans la galerie'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ]),
      ),
    );
    if (source == null) return;

    final XFile? photo = await _picker.pickImage(source: source, imageQuality: 80);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    if (!mounted) return;

    final note = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _Apercu(bytes: bytes)),
    );
    if (note == null) return;

    final nom = photo.name.isNotEmpty ? photo.name : 'ordonnance.jpg';
    final err = await AuthService.envoyerOrdonnance(bytes, nom, note);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(err ?? 'Ordonnance envoyée au pharmacien'),
    ));
    if (err == null) _charger();
  }

  Chip _chip(String statut) {
    switch (statut) {
      case 'VALIDEE':
        return Chip(label: const Text('Validée'), backgroundColor: Colors.green.shade100);
      case 'REJETEE':
        return Chip(label: const Text('Rejetée'), backgroundColor: Colors.red.shade100);
      default:
        return Chip(label: const Text('En attente'), backgroundColor: Colors.orange.shade100);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Mes Ordonnances'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _charger),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nouvelle,
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('Nouvelle ordonnance'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _ordonnances.isEmpty
              ? const Center(child: Text('Aucune ordonnance envoyée'))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                  itemCount: _ordonnances.length,
                  itemBuilder: (context, i) {
                    final o = _ordonnances[i];
                    final statut = o['statut'] as String;
                    final motif = o['motif_rejet'];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.assignment, color: Colors.teal),
                        title: Text(o['numero_ordonnance'],
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Envoyée le ${o['date_envoi']}'
                          '${motif != null ? '\nMotif : $motif' : ''}',
                        ),
                        trailing: _chip(statut),
                      ),
                    );
                  },
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
      appBar: AppBar(
        title: const Text('Aperçu de l\'ordonnance'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(widget.bytes, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noteCtrl,
            decoration: const InputDecoration(
              labelText: 'Note pour le pharmacien (facultatif)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, _noteCtrl.text),
              icon: const Icon(Icons.send),
              label: const Text('Envoyer'),
            ),
          ),
        ]),
      ),
    );
  }
}