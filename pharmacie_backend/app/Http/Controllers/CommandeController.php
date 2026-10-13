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
    private function verifierRegle(Request $request, array $ids): array
    {
        $besoinOrdonnance = DB::table('medicaments')
            ->whereIn('id', $ids)
            ->where('necessite_ordonnance', 1)
            ->exists();

        if (!$besoinOrdonnance) {
            return ['ok' => true, 'ordonnance_id' => null];
        }

        $ordonnances = Ordonnance::where('patient_id', $request->user()->id);

        $validee = (clone $ordonnances)->where('statut', 'VALIDEE')->orderByDesc('id')->first();
        if ($validee) {
            return ['ok' => true, 'ordonnance_id' => $validee->id];
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

        $resultat = $this->verifierRegle($request, $ids);
        if (!$resultat['ok']) {
            return response()->json($resultat, 422);
        }

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

        $commande = DB::transaction(function () use ($request, $data, $pharmacieId, $resultat, $prix, $montantMedicaments, $fraisLivraison) {
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