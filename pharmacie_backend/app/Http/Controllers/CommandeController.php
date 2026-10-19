<?php

namespace App\Http\Controllers;

use App\Models\Ordonnance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CommandeController extends Controller
{
    /**
     * Règle de gestion : une commande contenant un médicament sur ordonnance
     * exige au moins une ordonnance VALIDEE du patient.
     */
    private function verifierRegle(Request $request, array $ids, bool $verrou = false): array
    {
        $besoinOrdonnance = DB::table('medicaments')
            ->whereIn('id', $ids)
            ->where('necessite_ordonnance', 1)
            ->exists();

        if (!$besoinOrdonnance) {
            return ['ok' => true, 'ordonnance_id' => null];
        }

        $ordonnances = Ordonnance::where('patient_id', $request->user()->id);

        // Une ordonnance validée ne sert qu'à UNE commande : on exclut celles déjà utilisées
        $dejaUtilisees = DB::table('commandes')->whereNotNull('ordonnance_id')->select('ordonnance_id');

        $requete = (clone $ordonnances)
            ->where('statut', 'VALIDEE')
            ->whereNotIn('id', $dejaUtilisees)
            ->orderByDesc('id');
        if ($verrou) {
            $requete->lockForUpdate(); // évite deux commandes simultanées avec la même ordonnance
        }
        $validee = $requete->first();
        if ($validee) {
            return ['ok' => true, 'ordonnance_id' => $validee->id];
        }

        if ((clone $ordonnances)->where('statut', 'VALIDEE')->exists()) {
            return [
                'ok' => false,
                'code' => 'ORDONNANCE_DEJA_UTILISEE',
                'message' => 'Votre ordonnance validée a déjà été utilisée pour une commande. Veuillez en envoyer une nouvelle.',
            ];
        }

        if ((clone $ordonnances)->where('statut', 'EN_ATTENTE')->exists()) {
            return [
                'ok' => false,
                'code' => 'ORDONNANCE_EN_ATTENTE',
                'message' => 'Votre ordonnance est en cours de validation par le pharmacien.',
            ];
        }

        if ((clone $ordonnances)->where('statut', 'REJETEE')->exists()) {
            return [
                'ok' => false,
                'code' => 'ORDONNANCE_REJETEE',
                'message' => 'Votre ordonnance a été rejetée. Veuillez en envoyer une nouvelle.',
            ];
        }

        return [
            'ok' => false,
            'code' => 'AUCUNE_ORDONNANCE',
            'message' => 'Ce panier contient un médicament sur ordonnance. Veuillez d\'abord envoyer votre ordonnance.',
        ];
    }

    // POST /api/commande/verifier : contrôle seul, n'enregistre rien
    public function verifier(Request $request)
    {
        $data = $request->validate([
            'medicament_ids' => 'required|array|min:1',
            'medicament_ids.*' => 'required|integer',
        ]);

        $resultat = $this->verifierRegle($request, $data['medicament_ids']);

        if (!$resultat['ok']) {
            return response()->json($resultat, 422);
        }

        return response()->json(['ok' => true]);
    }

    // POST /api/commande : crée la commande si la règle est respectée
    public function store(Request $request)
    {
        $data = $request->validate([
            'adresse_livraison' => 'required|string|max:255',
            'lignes' => 'required|array|min:1',
            'lignes.*.medicament_id' => 'required|integer|exists:medicaments,id',
            'lignes.*.quantite' => 'required|integer|min:1|max:99',
        ]);

        $ids = collect($data['lignes'])->pluck('medicament_id')->unique()->values()->all();

        $pharmacieId = DB::table('pharmacies')->value('id');
        if (!$pharmacieId) {
            return response()->json(['message' => 'Aucune pharmacie disponible.'], 422);
        }

        // Les prix viennent de la base, jamais du téléphone
        $prix = DB::table('medicaments')->whereIn('id', $ids)->pluck('prix', 'id');

        $montantMedicaments = 0;
        foreach ($data['lignes'] as $ligne) {
            $montantMedicaments += $prix[$ligne['medicament_id']] * $ligne['quantite'];
        }
        $fraisLivraison = 1000;

        $refus = null;
        $commande = DB::transaction(function () use ($request, $data, $ids, $pharmacieId, $prix, $montantMedicaments, $fraisLivraison, &$refus) {
            // La règle est contrôlée ICI, au moment de la création, dans la transaction
            $resultat = $this->verifierRegle($request, $ids, true);
            if (!$resultat['ok']) {
                $refus = $resultat;
                return null;
            }

            $numero = 'CMD-' . strtoupper(Str::random(6));

            $id = DB::table('commandes')->insertGetId([
                'numero_commande' => $numero,
                'patient_id' => $request->user()->id,
                'pharmacie_id' => $pharmacieId,
                'ordonnance_id' => $resultat['ordonnance_id'],
                'adresse_livraison' => $data['adresse_livraison'],
                'montant_medicaments' => $montantMedicaments,
                'frais_livraison' => $fraisLivraison,
                'montant_total' => $montantMedicaments + $fraisLivraison,
                'statut' => 'CREEE',
            ]);

            foreach ($data['lignes'] as $ligne) {
                DB::table('lignes_commande')->insert([
                    'commande_id' => $id,
                    'medicament_id' => $ligne['medicament_id'],
                    'quantite' => $ligne['quantite'],
                    'prix_unitaire' => $prix[$ligne['medicament_id']],
                ]);
            }

            return ['id' => $id, 'numero_commande' => $numero];
        });

        if ($refus) {
            return response()->json($refus, 422);
        }

        return response()->json([
            'message' => 'Commande créée',
            'commande' => [
                'id' => $commande['id'],
                'numero_commande' => $commande['numero_commande'],
                'montant_total' => $montantMedicaments + $fraisLivraison,
                'statut' => 'CREEE',
            ],
        ], 201);
    }
}