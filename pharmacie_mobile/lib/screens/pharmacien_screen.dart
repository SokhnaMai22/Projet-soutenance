// lib/screens/pharmacien_screen.dart : espace pharmacien (voir l'ordonnance, valider, rejeter)

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/photos.dart';
import 'login_screen.dart';
import 'commandes_pharmacien_tab.dart';
import 'ajouter_medicament_tab.dart';

class PharmacienScreen extends StatefulWidget {
  const PharmacienScreen({super.key});

  @override
  State<PharmacienScreen> createState() => _PharmacienScreenState();
}

class _PharmacienScreenState extends State<PharmacienScreen> {
  List<dynamic> _liste = [];
  bool _chargement = true;
  String _filtre = 'EN_ATTENTE';
  int _onglet = 0;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final l = await AuthService.toutesOrdonnances();
    if (!mounted) return;
    setState(() {
      _liste = l;
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

  int _compte(String statut) =>
      _liste.where((o) => o['statut'] == statut).length;

  Future<void> _valider(int id) async {
    final ok = await AuthService.validerOrdonnance(id);
    if (!mounted) return;
    _message(ok ? 'Ordonnance validée' : 'Erreur lors de la validation',
        erreur: !ok);
    if (ok) _charger();
  }

  Future<void> _rejeter(int id) async {
    final ctrl = TextEditingController();
    final motif = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Motif du rejet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  'Ordonnance illisible',
                  'Ordonnance expirée',
                  'Photo incomplète',
                ]
                    .map((t) => ActionChip(
                          label: Text(t, style: const TextStyle(fontSize: 12)),
                          onPressed: () => setD(() => ctrl.text = t),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  hintText: 'Ex : ordonnance illisible',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.rouge),
              child: const Text('Rejeter'),
            ),
          ],
        ),
      ),
    );
    if (motif == null) return;
    if (motif.isEmpty) {
      _message('Le motif est obligatoire', erreur: true);
      return;
    }
    final ok = await AuthService.rejeterOrdonnance(id, motif);
    if (!mounted) return;
    _message(ok ? 'Ordonnance rejetée' : 'Erreur lors du rejet', erreur: !ok);
    if (ok) _charger();
  }

  @override
  Widget build(BuildContext context) {
    final nom = AuthService.user?['name']?.toString() ?? 'Pharmacien';
    final visibles = _filtre == 'TOUTES'
        ? _liste
        : _liste.where((o) => o['statut'] == _filtre).toList();

    return Scaffold(
      backgroundColor: AppColors.fond,
            bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description),
              label: 'Ordonnances'),
                    NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Commandes'),
          NavigationDestination(
              icon: Icon(Icons.add_box_outlined),
              selectedIcon: Icon(Icons.add_box),
              label: 'Médicaments'),
        ],
      ),
            body: _onglet == 2
          ? const SafeArea(child: AjouterMedicamentTab())
          : _onglet == 1
          ? const SafeArea(child: CommandesPharmacienTab())
          : RefreshIndicator(
        onRefresh: _charger,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _entete(nom)),
            SliverToBoxAdapter(child: _filtres()),
            if (_chargement)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visibles.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Text('Aucune ordonnance dans cette catégorie',
                      style: TextStyle(color: AppColors.gris)),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _carte(visibles[i] as Map<String, dynamic>),
                    childCount: visibles.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _entete(String nom) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          18, MediaQuery.of(context).padding.top + 14, 18, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.vertFonce, AppColors.vert],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Column(
        children: [
          Row(children: [
            PhotoRonde(
                dossier: 'profils', fichier: 'pharmacien.jpg', nom: nom, taille: 52),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                  const Text('Espace pharmacien',
                      style: TextStyle(color: Colors.white70, fontSize: 12.5)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _charger,
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                AuthService.deconnexion();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            _compteur('En attente', _compte('EN_ATTENTE'), AppColors.orange),
            const SizedBox(width: 10),
            _compteur('Validées', _compte('VALIDEE'), AppColors.vertFonce),
            const SizedBox(width: 10),
            _compteur('Rejetées', _compte('REJETEE'), AppColors.rouge),
          ]),
        ],
      ),
    );
  }

  Widget _compteur(String titre, int n, Color couleur) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Text('$n',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: couleur)),
          Text(titre,
              style: const TextStyle(fontSize: 11.5, color: AppColors.gris)),
        ]),
      ),
    );
  }

  Widget _filtres() {
    const entrees = [
      ['EN_ATTENTE', 'En attente'],
      ['VALIDEE', 'Validées'],
      ['REJETEE', 'Rejetées'],
      ['TOUTES', 'Toutes'],
    ];
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        itemCount: entrees.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final actif = _filtre == entrees[i][0];
          return GestureDetector(
            onTap: () => setState(() => _filtre = entrees[i][0]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: actif ? AppColors.vert : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: actif ? null : ombreCarte(),
              ),
              child: Text(entrees[i][1],
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: actif ? Colors.white : AppColors.texte)),
            ),
          );
        },
      ),
    );
  }

  Widget _carte(Map<String, dynamic> o) {
    final id = int.tryParse(o['id'].toString()) ?? 0;
    final enAttente = o['statut'] == 'EN_ATTENTE';
    final patient = o['patient']?['name'] ?? 'Patient';
    final note = o['note_patient'];
    final motif = o['motif_rejet'];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: decoCarte(),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo de l'ordonnance : toucher pour agrandir et lire
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ZoomOrdonnanceScreen(
                    id: id, titre: o['numero_ordonnance'].toString()),
              ),
            ),
            child: Stack(
              children: [
                ImageOrdonnance(id: id, hauteur: 190, largeur: double.infinity),
                Positioned(
                  right: 10,
                  bottom: 10,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.zoom_in, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('Agrandir',
                          style: TextStyle(color: Colors.white, fontSize: 12)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(
                    child: Text(o['numero_ordonnance'].toString(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                  ),
                  StatutOrdonnance(o['statut'].toString()),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: AppColors.gris),
                  const SizedBox(width: 4),
                  Text('$patient · ${o['date_envoi']}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.gris)),
                ]),
                if (note != null && note.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.fond,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('Note du patient : $note',
                        style: const TextStyle(fontSize: 12.5)),
                  ),
                ],
                if (motif != null) ...[
                  const SizedBox(height: 8),
                  Text('Motif du rejet : $motif',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.rouge)),
                ],
                if (enAttente) ...[
                  const SizedBox(height: 14),
                  Row(children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _valider(id),
                        icon: const Icon(Icons.check),
                        label: const Text('Valider'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _rejeter(id),
                        icon: const Icon(Icons.close),
                        label: const Text('Rejeter'),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.rouge),
                      ),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}