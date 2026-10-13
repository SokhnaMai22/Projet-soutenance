// lib/screens/paiement_screen.dart

import 'package:flutter/material.dart';
import '../models/panier.dart';
import 'suivi_commande_screen.dart'; // <-- 1. Import du suivi de commande

class PaiementScreen extends StatefulWidget {
  final double montantTotal;

  const PaiementScreen({super.key, required this.montantTotal});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  String _moyenPaiement = 'WAVE';
  final _telephoneController = TextEditingController(text: '77 123 45 67');
  final _adresseController = TextEditingController(text: 'Dakar, Médina Rue 22 x 15');
  bool _enCoursDeTraitement = false;

  void _validerPaiement() async {
    if (_telephoneController.text.isEmpty || _adresseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Veuillez remplir l\'adresse et le numéro de téléphone.'),
        ),
      );
      return;
    }

    setState(() {
      _enCoursDeTraitement = true;
    });

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() {
      _enCoursDeTraitement = false;
    });

    PanierService.vider();

    final reference = _moyenPaiement == 'WAVE' ? 'WAV-SN-83921' : 'OM-SN-49201';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 8),
            const Text('Paiement Réussi !'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Montant débité : ${widget.montantTotal.toInt()} FCFA',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text('Opérateur : $_moyenPaiement'),
            Text('Réf. Transaction : $reference', style: const TextStyle(fontFamily: 'monospace')),
            Text('Numéro : ${_telephoneController.text}'),
            const Divider(height: 20),
            const Text(
              'Votre commande a été transmise à la pharmacie pour préparation.',
              style: TextStyle(fontSize: 13, color: Colors.blueGrey),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.delivery_dining),
            label: const Text('Suivre ma livraison en direct'),
            onPressed: () {
              Navigator.pop(ctx); // Ferme la boîte de dialogue
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => SuiviCommandeScreen(
                    montantTotal: widget.montantTotal,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Paiement Sécurisé'),
        backgroundColor: Colors.teal.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              color: Colors.teal.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total à payer :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text(
                      '${widget.montantTotal.toInt()} FCFA',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('1. Adresse de livraison à Dakar :', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _adresseController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on, color: Colors.teal),
                hintText: 'Ex: Fann Résidence, Dakar',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            const Text('2. Opérateur de paiement mobile :', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildOptionPaiement(
              id: 'WAVE',
              nom: 'Wave Digital Finance',
              sousTitre: 'Sans frais supplémentaires',
              couleur: const Color(0xFF1DC3F4),
              icone: Icons.waves,
            ),
            const SizedBox(height: 10),
            _buildOptionPaiement(
              id: 'ORANGE_MONEY',
              nom: 'Orange Money Sénégal',
              sousTitre: 'Validation par SMS / notification',
              couleur: const Color(0xFFFF7900),
              icone: Icons.phone_android,
            ),
            const SizedBox(height: 20),
            const Text('3. Numéro de téléphone Mobile Money :', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _telephoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, color: Colors.teal),
                prefixText: '+221 ',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _moyenPaiement == 'WAVE' ? const Color(0xFF1DC3F4) : const Color(0xFFFF7900),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _enCoursDeTraitement ? null : _validerPaiement,
                child: _enCoursDeTraitement
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Colors.white),
                          SizedBox(width: 14),
                          Text('Connexion avec l\'opérateur...'),
                        ],
                      )
                    : Text(
                        'Payer ${widget.montantTotal.toInt()} FCFA avec $_moyenPaiement',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionPaiement({
    required String id,
    required String nom,
    required String sousTitre,
    required Color couleur,
    required IconData icone,
  }) {
    final estSelectionne = _moyenPaiement == id;
    return InkWell(
      onTap: () => setState(() => _moyenPaiement = id),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: estSelectionne ? couleur : Colors.grey.shade300, width: estSelectionne ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: couleur.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icone, color: couleur, size: 28),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: estSelectionne ? couleur : Colors.black87)),
                  Text(sousTitre, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Radio<String>(
              value: id,
              groupValue: _moyenPaiement,
              activeColor: couleur,
              onChanged: (val) => setState(() => _moyenPaiement = val!),
            ),
          ],
        ),
      ),
    );
  }
}