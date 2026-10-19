// lib/screens/catalogue_screen.dart : espace patient (catalogue, ordonnances, suivi, compte)

import 'package:flutter/material.dart';
import '../models/medicament.dart';
import '../models/panier.dart';
import '../services/auth_service.dart';
import '../services/catalogue_service.dart';
import '../theme/app_theme.dart';
import '../widgets/medicament_card.dart';
import '../widgets/photos.dart';
import 'login_screen.dart';
import 'ordonnance_screen.dart';
import 'panier_screen.dart';
import 'suivi_commande_screen.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  int _onglet = 0;

  void _deconnexion() {
    AuthService.deconnexion();
    PanierService.vider();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _OngletCatalogue(
        key: const ValueKey('catalogue'),
        versOrdonnances: () => setState(() => _onglet = 1),
      ),
      const OrdonnanceScreen(key: ValueKey('ordonnances')),
      const SuiviCommandeScreen(key: ValueKey('suivi')),
      _OngletCompte(key: const ValueKey('compte'), onDeconnexion: _deconnexion),
    ];

    return Scaffold(
      body: pages[_onglet],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _onglet,
        onDestinationSelected: (i) => setState(() => _onglet = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront, color: AppColors.vertFonce),
              label: 'Catalogue'),
          NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon: Icon(Icons.description, color: AppColors.vertFonce),
              label: 'Ordonnances'),
          NavigationDestination(
              icon: Icon(Icons.delivery_dining_outlined),
              selectedIcon: Icon(Icons.delivery_dining, color: AppColors.vertFonce),
              label: 'Suivi'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: AppColors.vertFonce),
              label: 'Compte'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- Onglet catalogue

class _OngletCatalogue extends StatefulWidget {
  final VoidCallback versOrdonnances;
  const _OngletCatalogue({super.key, required this.versOrdonnances});

  @override
  State<_OngletCatalogue> createState() => _OngletCatalogueState();
}

class _OngletCatalogueState extends State<_OngletCatalogue> {
  bool _chargement = true;
  String? _erreur;
  String _filtre = 'TOUS'; // TOUS, LIBRE, ORDONNANCE ou nom de catégorie
  String _recherche = '';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    final err = await CatalogueService.charger();
    if (!mounted) return;
    setState(() {
      _erreur = err;
      _chargement = false;
    });
  }

  List<Medicament> get _affiches {
    return CatalogueService.medicaments.where((m) {
      if (_recherche.isNotEmpty &&
          !m.nom.toLowerCase().contains(_recherche.toLowerCase())) {
        return false;
      }
      switch (_filtre) {
        case 'TOUS':
          return true;
        case 'LIBRE':
          return !m.necessiteOrdonnance;
        case 'ORDONNANCE':
          return m.necessiteOrdonnance;
        default:
          return m.categorie == _filtre;
      }
    }).toList();
  }

  void _ouvrirPanier() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PanierScreen()),
    ).then((_) => setState(() {}));
  }

  void _ajouter(Medicament m) {
    setState(() => PanierService.ajouter(m));
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: m.necessiteOrdonnance ? AppColors.orange : AppColors.vertFonce,
        content: Text(m.necessiteOrdonnance
            ? '${m.nom} ajouté. Une ordonnance validée sera exigée à la commande.'
            : '${m.nom} ajouté au panier'),
        action: SnackBarAction(
          label: 'Panier',
          textColor: Colors.white,
          onPressed: _ouvrirPanier,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prenom = (AuthService.user?['name'] ?? '').toString().split(' ').first;
    final liste = _affiches;

    return Scaffold(
      backgroundColor: AppColors.fond,
      body: RefreshIndicator(
        onRefresh: _charger,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _entete(prenom)),
            if (_chargement)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_erreur != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _etatErreur(),
              )
            else ...[
              SliverToBoxAdapter(child: _banniereOrdonnance()),
              SliverToBoxAdapter(child: _pharmacies()),
              SliverToBoxAdapter(child: _filtres()),
              if (liste.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text('Aucun médicament trouvé',
                        style: TextStyle(color: AppColors.gris)),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      mainAxisExtent: 310,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => MedicamentCard(
                        medicament: liste[i],
                        onTap: () => _details(liste[i]),
                        onAjouter: () => _ajouter(liste[i]),
                      ),
                      childCount: liste.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _entete(String prenom) {
    final nb = PanierService.nombreArticles;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, MediaQuery.of(context).padding.top + 12, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        boxShadow: ombreCarte(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const LogoPharma(taille: 46),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PharmaSanté Sénégal',
                      style: TextStyle(
                        color: AppColors.vertFonce,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      prenom.isEmpty
                          ? 'Votre pharmacie en ligne à Dakar'
                          : 'Bonjour $prenom · votre pharmacie en ligne',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppColors.gris,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: _ouvrirPanier,
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 52,
                  height: 46,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_cart_outlined,
                              color: AppColors.texte, size: 24),
                          Text('Panier',
                              style: TextStyle(fontSize: 10.5, color: AppColors.texte)),
                        ],
                      ),
                      if (nb > 0)
                        Positioned(
                          right: 2,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.vert,
                              shape: BoxShape.circle,
                            ),
                            child: Text('$nb',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (t) => setState(() => _recherche = t),
            decoration: InputDecoration(
              hintText: 'Rechercher un médicament…',
              hintStyle: const TextStyle(color: AppColors.gris),
              suffixIcon: const Icon(Icons.search, color: AppColors.texte),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              filled: true,
              fillColor: Colors.white,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: const BorderSide(color: AppColors.vert, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _banniereOrdonnance() {
    return GestureDetector(
      onTap: widget.versOrdonnances,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.orangeClair,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.orange.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.orange,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.photo_camera_outlined, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Vous avez une ordonnance ?',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: AppColors.texte)),
                  SizedBox(height: 2),
                  Text('Photographiez-la : le pharmacien la valide.',
                      style: TextStyle(fontSize: 12, color: AppColors.gris)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.orange),
          ],
        ),
      ),
    );
  }

  Widget _pharmacies() {
    final liste = CatalogueService.pharmacies;
    if (liste.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Text('Pharmacies partenaires',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.texte)),
        ),
        SizedBox(
          height: 104,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: liste.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = liste[i];
              return Container(
                width: 230,
                padding: const EdgeInsets.all(12),
                decoration: decoCarte(),
                child: Row(
                  children: [
                    PhotoRonde(
                        dossier: 'pharmacies',
                        fichier: p.photo,
                        nom: p.pharmacienNom.isEmpty ? p.nom : p.pharmacienNom,
                        taille: 56),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nom,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.texte)),
                          const SizedBox(height: 3),
                          Text(p.pharmacienNom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColors.vertFonce)),
                          Text(p.quartier,
                              style: const TextStyle(
                                  fontSize: 11, color: AppColors.gris)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filtres() {
    final entrees = <MapEntry<String, String>>[
      const MapEntry('TOUS', 'Tous'),
      const MapEntry('LIBRE', 'Vente libre'),
      const MapEntry('ORDONNANCE', 'Sur ordonnance'),
      ...CatalogueService.categories.map((c) => MapEntry(c, c)),
    ];
    return SizedBox(
      height: 62,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        itemCount: entrees.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = entrees[i];
          final actif = _filtre == e.key;
          return GestureDetector(
            onTap: () => setState(() => _filtre = e.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: actif ? AppColors.vert : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: actif ? null : ombreCarte(),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: actif ? Colors.white : AppColors.texte,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _etatErreur() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.gris),
          const SizedBox(height: 12),
          Text(_erreur!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.gris)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _charger,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _details(Medicament m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              PhotoMedicament(fichier: m.image, hauteur: 200, rayon: 18),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(m.nom,
                        style: const TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: AppColors.texte)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: m.necessiteOrdonnance
                          ? AppColors.orangeClair
                          : AppColors.vertClair,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      m.necessiteOrdonnance ? 'Sur ordonnance' : 'Vente libre',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: m.necessiteOrdonnance
                            ? AppColors.orange
                            : AppColors.vertFonce,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text('${m.forme} · ${m.dosage} · ${m.categorie}',
                  style: const TextStyle(color: AppColors.gris, fontSize: 13)),
              const SizedBox(height: 12),
              Text(m.description,
                  style: const TextStyle(fontSize: 14, height: 1.4)),
              if (m.necessiteOrdonnance) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.orangeClair,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(children: [
                    Icon(Icons.info_outline, color: AppColors.orange, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Une ordonnance validée par le pharmacien est exigée à la commande.',
                        style: TextStyle(fontSize: 12.5),
                      ),
                    ),
                  ]),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.fond,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  PhotoRonde(
                      dossier: 'pharmacies',
                      fichier: m.pharmaciePhoto,
                      nom: m.pharmacienNom.isEmpty ? m.pharmacieNom : m.pharmacienNom,
                      taille: 52),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m.pharmacieNom,
                            style: const TextStyle(fontWeight: FontWeight.w800)),
                        if (m.pharmacienNom.isNotEmpty)
                          Text('Pharmacien : ${m.pharmacienNom}',
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.vertFonce)),
                        Text(
                          '${m.pharmacieQuartier} · ${m.stockDisponible} boîtes en stock',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.gris),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('${m.prix.toInt()} FCFA',
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: AppColors.vertFonce)),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Ajouter au panier'),
                    onPressed: m.stockDisponible > 0
                        ? () {
                            Navigator.pop(ctx);
                            _ajouter(m);
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Onglet compte

class _OngletCompte extends StatelessWidget {
  final VoidCallback onDeconnexion;
  const _OngletCompte({super.key, required this.onDeconnexion});

  @override
  Widget build(BuildContext context) {
    final nom = AuthService.user?['name']?.toString() ?? 'Patient';
    final email = AuthService.user?['email']?.toString() ?? '';
    return Scaffold(
      backgroundColor: AppColors.fond,
      appBar: AppBar(title: const Text('Mon compte')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: decoCarte(),
            child: Row(children: [
              PhotoRonde(dossier: 'profils', fichier: 'patient.jpg', nom: nom, taille: 64),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(nom,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(email,
                        style: const TextStyle(color: AppColors.gris, fontSize: 13)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.vertClair,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('Patient',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.vertFonce)),
                    ),
                  ],
                ),
              ),
            ]),
          ),
          const SizedBox(height: 28),
          const Center(child: LogoPharma(taille: 72)),
          const SizedBox(height: 8),
          const Center(
            child: Text('PharmaSanté Sénégal',
                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.vertFonce)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              onPressed: onDeconnexion,
              icon: const Icon(Icons.logout),
              label: const Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.rouge,
                side: const BorderSide(color: AppColors.rouge),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}