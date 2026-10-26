// lib/screens/gestion_catalogue_tab.dart : le pharmacien gère le catalogue depuis l'application
// - liste des médicaments (prix, stock) avec : modifier, modifier le stock, marquer indisponible, supprimer
// - ajouter un médicament (formulaire avec photo), ajouter une pharmacie, définir un stock

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/photos.dart';
import 'ajouter_medicament_tab.dart';

class GestionCatalogueTab extends StatefulWidget {
  const GestionCatalogueTab({super.key});

  @override
  State<GestionCatalogueTab> createState() => _GestionCatalogueTabState();
}

class _GestionCatalogueTabState extends State<GestionCatalogueTab> {
  List<dynamic> _medicaments = [];
  bool _chargement = true;
  bool _erreur = false;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = false;
    });
    try {
      final l = await ApiService.medicamentsGestion();
      if (!mounted) return;
      setState(() {
        _medicaments = l;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = true;
      });
    }
  }

  void _message(String texte, {bool erreur = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: erreur ? AppColors.rouge : AppColors.vertFonce,
      content: Text(texte),
    ));
  }

  Widget _champ(TextEditingController c, String label,
      {TextInputType? type, int lignes = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: c,
        keyboardType: type,
        maxLines: lignes,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  int _entier(dynamic v) => int.tryParse(v.toString().split('.').first) ?? 0;

  // ---------- Ajouter un médicament (formulaire avec photo) ----------
  Future<void> _ajouterMedicament() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Nouveau médicament')),
          body: const SafeArea(child: AjouterMedicamentTab()),
        ),
      ),
    );
    if (mounted) _charger();
  }

  // ---------- Ajouter une pharmacie ----------
  Future<void> _ajouterPharmacie() async {
    final nom = TextEditingController();
    final quartier = TextEditingController();
    final adresse = TextEditingController();
    final tel = TextEditingController();
    final titulaire = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ajouter une pharmacie'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _champ(nom, 'Nom de la pharmacie'),
            _champ(quartier, 'Quartier'),
            _champ(adresse, 'Adresse'),
            _champ(tel, 'Téléphone', type: TextInputType.phone),
            _champ(titulaire, 'Pharmacien titulaire'),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ajouter')),
        ],
      ),
    );
    final corps = {
      'nom': nom.text.trim(),
      'quartier': quartier.text.trim(),
      'adresse': adresse.text.trim(),
      'telephone': tel.text.trim(),
      'pharmacien_nom': titulaire.text.trim(),
    };
    for (final c in [nom, quartier, adresse, tel, titulaire]) {
      c.dispose();
    }
    if (ok != true) return;
    if (corps['nom']!.isEmpty) {
      _message('Le nom est obligatoire', erreur: true);
      return;
    }
    final err = await ApiService.creerPharmacie(corps);
    if (!mounted) return;
    _message(err ?? 'Pharmacie ajoutée', erreur: err != null);
  }

  // ---------- Définir / modifier un stock ----------
  Future<void> _definirStock({int? medicamentId}) async {
    List<dynamic> pharmacies;
    try {
      pharmacies = await ApiService.pharmacies();
    } catch (e) {
      _message('Impossible de charger les pharmacies', erreur: true);
      return;
    }
    if (!mounted) return;
    if (pharmacies.isEmpty || _medicaments.isEmpty) {
      _message('Ajoutez d\'abord une pharmacie et un médicament', erreur: true);
      return;
    }
    int? ph;
    int? med = medicamentId;
    final qte = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Définir un stock'),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButton<int>(
                isExpanded: true,
                hint: const Text('Pharmacie'),
                value: ph,
                items: pharmacies
                    .map<DropdownMenuItem<int>>((p) => DropdownMenuItem(
                        value: _entier(p['id']),
                        child: Text(p['nom'].toString(),
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setD(() => ph = v),
              ),
              DropdownButton<int>(
                isExpanded: true,
                hint: const Text('Médicament'),
                value: med,
                items: _medicaments
                    .map<DropdownMenuItem<int>>((m) => DropdownMenuItem(
                        value: _entier(m['id']),
                        child: Text('${m['nom']} ${m['dosage'] ?? ''}',
                            overflow: TextOverflow.ellipsis)))
                    .toList(),
                onChanged: (v) => setD(() => med = v),
              ),
              _champ(qte, 'Quantité disponible', type: TextInputType.number),
            ]),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Annuler')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Enregistrer')),
          ],
        ),
      ),
    );
    final q = int.tryParse(qte.text.trim());
    qte.dispose();
    if (ok != true) return;
    if (ph == null || med == null || q == null) {
      _message('Choisissez une pharmacie, un médicament et une quantité',
          erreur: true);
      return;
    }
    final err = await ApiService.definirStock(ph!, med!, q);
    if (!mounted) return;
    _message(err ?? 'Stock enregistré', erreur: err != null);
    if (err == null) _charger();
  }

  // ---------- Modifier prix / description ----------
  Future<void> _modifier(Map m) async {
    final prix = TextEditingController(text: _entier(m['prix']).toString());
    final description =
        TextEditingController(text: (m['description'] ?? '').toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Modifier ${m['nom']}'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _champ(prix, 'Prix (FCFA)', type: TextInputType.number),
            _champ(description, 'Description', lignes: 3),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Enregistrer')),
        ],
      ),
    );
    final p = int.tryParse(prix.text.trim());
    final d = description.text.trim();
    prix.dispose();
    description.dispose();
    if (ok != true) return;
    if (p == null) {
      _message('Le prix doit être un nombre', erreur: true);
      return;
    }
    final err = await ApiService.modifierMedicament(_entier(m['id']), p, d);
    if (!mounted) return;
    _message(err ?? 'Médicament modifié', erreur: err != null);
    if (err == null) _charger();
  }

  Future<bool> _confirmer(String titre, String texte, String bouton) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(titre),
        content: Text(texte),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(bouton)),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _indisponible(Map m) async {
    if (!await _confirmer('Marquer indisponible',
        '${m['nom']} ne sera plus proposé aux patients (stock mis à 0 partout).',
        'Confirmer')) return;
    final err = await ApiService.rendreIndisponible(_entier(m['id']));
    if (!mounted) return;
    _message(err ?? 'Médicament marqué indisponible', erreur: err != null);
    if (err == null) _charger();
  }

  Future<void> _supprimer(Map m) async {
    if (!await _confirmer('Supprimer',
        'Supprimer définitivement ${m['nom']} du catalogue ?', 'Supprimer')) {
      return;
    }
    final err = await ApiService.supprimerMedicament(_entier(m['id']));
    if (!mounted) return;
    _message(err ?? 'Médicament supprimé', erreur: err != null);
    if (err == null) _charger();
  }

  // ---------- Affichage ----------
  Widget _bouton(IconData icone, String texte, VoidCallback f) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: f,
        icon: Icon(icone, size: 18),
        label: Text(texte,
            style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
      ),
    );
  }

  Widget _carte(Map m) {
    final stock = _entier(m['stock_total']);
    final dispo = stock > 0;
    final image = m['image']?.toString();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: ombreCarte(),
      ),
      child: Row(children: [
        SizedBox(
          width: 64,
          height: 64,
          child: PhotoMedicament(
              fichier: (image == null || image.isEmpty) ? null : image,
              hauteur: 64,
              rayon: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${m['nom']} ${m['dosage'] ?? ''}'.trim(),
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
            const SizedBox(height: 2),
            Text('${_entier(m['prix'])} FCFA',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(dispo ? 'Stock total : $stock' : 'Indisponible',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: dispo ? AppColors.vertFonce : AppColors.rouge)),
          ]),
        ),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'modifier') _modifier(m);
            if (v == 'stock') _definirStock(medicamentId: _entier(m['id']));
            if (v == 'indispo') _indisponible(m);
            if (v == 'supprimer') _supprimer(m);
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'modifier', child: Text('Modifier prix / description')),
            PopupMenuItem(value: 'stock', child: Text('Modifier le stock')),
            PopupMenuItem(value: 'indispo', child: Text('Marquer indisponible')),
            PopupMenuItem(value: 'supprimer', child: Text('Supprimer')),
          ],
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _ajouterMedicament,
        icon: const Icon(Icons.add),
        label: const Text('Médicament'),
      ),
      body: RefreshIndicator(
        onRefresh: _charger,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 4, 4, 12),
              child: Text('Gérer le catalogue',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            ),
            Row(children: [
              _bouton(Icons.local_pharmacy_outlined, 'Ajouter une pharmacie',
                  _ajouterPharmacie),
              const SizedBox(width: 10),
              _bouton(Icons.inventory_2_outlined, 'Définir un stock',
                  () => _definirStock()),
            ]),
            const SizedBox(height: 16),
            if (_chargement)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()))
            else if (_erreur)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                      child: Text('Impossible de charger le catalogue.\nTirez vers le bas pour réessayer.',
                          textAlign: TextAlign.center)))
            else if (_medicaments.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                      child: Text('Aucun médicament.\nAppuyez sur « Médicament » pour en ajouter un.',
                          textAlign: TextAlign.center)))
            else
              ..._medicaments.map((m) => _carte(m as Map)),
          ],
        ),
      ),
    );
  }
}