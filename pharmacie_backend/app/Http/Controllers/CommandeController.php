<?php

namespace App\Http\Controllers;

use App\Models\Ordonnance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class CommandeController extends Controller
{
    /** Regroupe des lignes de panier en [medicament_id => quantité totale]. */
    private function regrouper(array $lignes): array
    {
        $quantites = [];
        foreach ($lignes as $l) {
            $id = (int) $l['medicament_id'];
            $quantites[$id] = ($quantites[$id] ?? 0) + (int) $l['quantite'];
        }
        return $quantites;
    }

    /**
     * Règle de gestion : un panier contenant un médicament sur ordonnance exige une
     * ordonnance VALIDEE du patient, jamais utilisée, qui AUTORISE ces médicaments
     * dans ces quantités (liste fixée par le pharmacien à la validation).
     */
    private function verifierRegle(Request $request, array $quantites, bool $verrou = false): array
    {
        $idsRx = DB::table('medicaments')
            ->whereIn('id', array_keys($quantites))
            ->where('necessite_ordonnance', 1)
            ->pluck('id')
            ->all();

        if (!$idsRx) {
            return ['ok' => true, 'ordonnance_id' => null];
        }

        $ordonnances = Ordonnance::where('patient_id', $request->user()->id);
        $dejaUtilisees = DB::table('commandes')->whereNotNull('ordonnance_id')->select('ordonnance_id');

        $requete = (clone $ordonnances)
            ->where('statut', 'VALIDEE')
            ->whereNotIn('id', $dejaUtilisees)
            ->orderByDesc('id');
        if ($verrou) {
            $requete->lockForUpdate(); // évite deux commandes simultanées avec la même ordonnance
        }
        $disponibles = $requete->get();

        foreach ($disponibles as $o) {
            $autorises = DB::table('ordonnance_medicaments')
                ->where('ordonnance_id', $o->id)
                ->pluck('quantite_max', 'medicament_id');

            $couvre = true;
            foreach ($idsRx as $mid) {
                if (($autorises[$mid] ?? 0) < $quantites[$mid]) {
                    $couvre = false;
                    break;
                }
            }
            if ($couvre) {
                return ['ok' => true, 'ordonnance_id' => $o->id];
            }
        }

        if ($disponibles->isNotEmpty()) {
            return [
                'ok' => false,
                'code' => 'MEDICAMENT_NON_AUTORISE',
                'message' => 'Votre ordonnance validée ne couvre pas ces médicaments ou ces quantités.',
            ];
        }

        if ((clone $ordonnances)->where('statut', 'EN_ATTENTE')->exists()) {
            return [
                'ok' => false,
                'code' => 'ORDONNANCE_EN_ATTENTE',
                'message' => 'Votre ordonnance est en cours de validation par le pharmacien.',
            ];
        }

        if ((clone $ordonnances)->where('statut', 'VALIDEE')->exists()) {
            return [
                'ok' => false,
                'code' => 'ORDONNANCE_DEJA_UTILISEE',
                'message' => 'Votre ordonnance validée a déjà été utilisée pour une commande. Veuillez en envoyer une nouvelle.',
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

    /** Première pharmacie active qui a, en stock, TOUS les médicaments du panier. */
    private function choisirPharmacie(array $quantites, bool $verrou = false): ?int
    {
        $pharmacies = DB::table('pharmacies')->where('statut', 'ACTIVE')->orderBy('id')->pluck('id');

        foreach ($pharmacies as $pid) {
            $ok = true;
            foreach ($quantites as $mid => $q) {
                $requete = DB::table('stocks')->where('pharmacie_id', $pid)->where('medicament_id', $mid);
                if ($verrou) {
                    $requete->lockForUpdate();
                }
                $stock = $requete->value('quantite_disponible');
                if ($stock === null || $stock < $q) {
                    $ok = false;
                    break;
                }
            }
            if ($ok) {
                return (int) $pid;
            }
        }
        return null;
    }

    private function refusStock(): array
    {
        return [
            'ok' => false,
            'code' => 'STOCK_INSUFFISANT',
            'message' => 'Ces médicaments ne sont pas tous disponibles, en quantité suffisante, dans une même pharmacie.',
        ];
    }

    // POST /api/commande/verifier : contrôle seul, n'enregistre rien
    // Accepte soit 'lignes' (medicament_id + quantite), soit 'medicament_ids' (quantité 1 par défaut)
    public function verifier(Request $request)
    {
        $data = $request->validate([
            'medicament_ids'           => 'required_without:lignes|array|min:1',
            'medicament_ids.*'         => 'integer',
            'lignes'                   => 'required_without:medicament_ids|array|min:1',
            'lignes.*.medicament_id'   => 'required|integer',
            'lignes.*.quantite'        => 'required|integer|min:1|max:99',
        ]);

        if (!empty($data['lignes'])) {
            $quantites = $this->regrouper($data['lignes']);
        } else {
            $quantites = [];
            foreach ($data['medicament_ids'] as $id) {
                $quantites[(int) $id] = 1;
            }
        }

        $resultat = $this->verifierRegle($request, $quantites);
        if (!$resultat['ok']) {
            return response()->json($resultat, 422);
        }

        if ($this->choisirPharmacie($quantites) === null) {
            return response()->json($this->refusStock(), 422);
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

        $quantites = $this->regrouper($data['lignes']);
        $ids = array_keys($quantites);

        // Les prix viennent de la base, jamais du téléphone
        $prix = DB::table('medicaments')->whereIn('id', $ids)->pluck('prix', 'id');

        $montantMedicaments = 0;
        foreach ($quantites as $mid => $q) {
            $montantMedicaments += $prix[$mid] * $q;
        }
        $fraisLivraison = 1000;

        $refus = null;
        $commande = DB::transaction(function () use ($request, $data, $quantites, $prix, $montantMedicaments, $fraisLivraison, &$refus) {
            // Les règles sont contrôlées ICI, au moment de la création, dans la transaction
            $resultat = $this->verifierRegle($request, $quantites, true);
            if (!$resultat['ok']) {
                $refus = $resultat;
                return null;
            }

            $pharmacieId = $this->choisirPharmacie($quantites, true);
            if ($pharmacieId === null) {
                $refus = $this->refusStock();
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

            foreach ($quantites as $mid => $q) {
                DB::table('lignes_commande')->insert([
                    'commande_id' => $id,
                    'medicament_id' => $mid,
                    'quantite' => $q,
                    'prix_unitaire' => $prix[$mid],
                ]);

                // Le stock de la pharmacie diminue
                DB::table('stocks')
                    ->where('pharmacie_id', $pharmacieId)
                    ->where('medicament_id', $mid)
                    ->decrement('quantite_disponible', $q);
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