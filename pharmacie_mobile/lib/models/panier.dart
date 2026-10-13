// lib/models/panier.dart

import 'medicament.dart';

class ArticlePanier {
  final Medicament medicament;
  int quantite;

  ArticlePanier({
    required this.medicament,
    this.quantite = 1,
  });

  // Calcul du sous-total pour cet article
  double get total => medicament.prix * quantite;
}

class PanierService {
  // Liste des articles actuellement dans le panier
  static final List<ArticlePanier> articles = [];

  // Ajouter un médicament au panier
  static void ajouter(Medicament medicament) {
    final index = articles.indexWhere((a) => a.medicament.id == medicament.id);
    if (index != -1) {
      articles[index].quantite++;
    } else {
      articles.add(ArticlePanier(medicament: medicament, quantite: 1));
    }
  }

  // Diminuer la quantité ou retirer si 0
  static void diminuer(Medicament medicament) {
    final index = articles.indexWhere((a) => a.medicament.id == medicament.id);
    if (index != -1) {
      if (articles[index].quantite > 1) {
        articles[index].quantite--;
      } else {
        articles.removeAt(index);
      }
    }
  }

  // Supprimer un article
  static void supprimer(Medicament medicament) {
    articles.removeWhere((a) => a.medicament.id == medicament.id);
  }

  // Total général en FCFA
  static double get montantTotal {
    double total = 0;
    for (var a in articles) {
      total += a.total;
    }
    return total;
  }

  // Nombre total d'articles
  static int get nombreArticles {
    int count = 0;
    for (var a in articles) {
      count += a.quantite;
    }
    return count;
  }

  // Vider le panier après commande
  static void vider() {
    articles.clear();
  }
}