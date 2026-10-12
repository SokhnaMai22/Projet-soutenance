import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class PharmacienScreen extends StatefulWidget {
  const PharmacienScreen({super.key});

  @override
  State<PharmacienScreen> createState() => _PharmacienScreenState();
}

class _PharmacienScreenState extends State<PharmacienScreen> {
  List<dynamic> _liste = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _loading = true);
    final l = await AuthService.toutesOrdonnances();
    if (!mounted) return;
    setState(() {
      _liste = l;
      _loading = false;
    });
  }

  void _message(String texte) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(texte)));
  }

  Future<void> _valider(int id) async {
    final ok = await AuthService.validerOrdonnance(id);
    if (!mounted) return;
    _message(ok ? 'Ordonnance validée' : 'Erreur lors de la validation');
    if (ok) _charger();
  }

  Future<void> _rejeter(int id) async {
    final ctrl = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motif du rejet'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
              hintText: 'Ex : ordonnance illisible',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Rejeter')),
        ],
      ),
    );
    if (motif == null) return;
    if (motif.isEmpty) {
      _message('Le motif est obligatoire');
      return;
    }
    final ok = await AuthService.rejeterOrdonnance(id, motif);
    if (!mounted) return;
    _message(ok ? 'Ordonnance rejetée' : 'Erreur lors du rejet');
    if (ok) _charger();
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
        title: const Text('Espace Pharmacien'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _charger),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              AuthService.deconnexion();
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _liste.isEmpty
              ? const Center(child: Text('Aucune ordonnance reçue'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _liste.length,
                  itemBuilder: (context, i) {
                    final o = _liste[i];
                    final enAttente = o['statut'] == 'EN_ATTENTE';
                    final patient = o['patient']?['name'] ?? 'Patient';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(o['numero_ordonnance'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16)),
                                _chip(o['statut']),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text('Patient : $patient'),
                            if (o['note_patient'] != null)
                              Text('Note : ${o['note_patient']}'),
                            if (o['motif_rejet'] != null)
                              Text('Motif : ${o['motif_rejet']}',
                                  style: const TextStyle(color: Colors.red)),
                            if (enAttente) ...[
                              const SizedBox(height: 8),
                              Row(children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _valider(o['id']),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Valider'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _rejeter(o['id']),
                                    icon: const Icon(Icons.close),
                                    label: const Text('Rejeter'),
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white),
                                  ),
                                ),
                              ]),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}