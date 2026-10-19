<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

class LivraisonController extends Controller
{
       // Le livreur ne voit que les commandes que le pharmacien a marquées prêtes
    private const STATUTS_A_LIVRER = ['PRETE'];

    // Commandes que le pharmacien doit encore préparer
    private const STATUTS_A_PREPARER = ['CREEE', 'PAYEE', 'EN_PREPARATION'];

    private function requeteBase()
    {
        $tel = Schema::hasColumn('users', 'telephone') ? 'u.telephone' : 'NULL';

        return DB::table('commandes as c')
            ->join('users as u', 'u.id', '=', 'c.patient_id')
            ->join('pharmacies as p', 'p.id', '=', 'c.pharmacie_id')
            ->select(
                'c.id', 'c.numero_commande', 'c.adresse_livraison', 'c.montant_total',
                'c.frais_livraison', 'c.statut', 'c.date_commande', 'c.date_livraison', 'c.livreur_id',
                'u.name as patient_nom', DB::raw($tel . ' as patient_telephone'),
                'p.nom as pharmacie_nom', 'p.adresse as pharmacie_adresse', 'p.quartier as pharmacie_quartier'
            );
    }

    private function avecLignes($commandes)
    {
        $ids = collect($commandes)->pluck('id')->all();
        if (empty($ids)) {
            return [];
        }
        $lignes = DB::table('lignes_commande as l')
            ->join('medicaments as m', 'm.id', '=', 'l.medicament_id')
            ->whereIn('l.commande_id', $ids)
            ->select('l.commande_id', 'm.nom', 'l.quantite')
            ->get()
            ->groupBy('commande_id');

        return collect($commandes)->map(function ($c) use ($lignes) {
            $c->lignes = ($lignes[$c->id] ?? collect())->map(fn ($l) => ['nom' => $l->nom, 'quantite' => $l->quantite])->values();
            return $c;
        })->values()->all();
    }

    // GET /api/livraisons : tout l'écran du livreur en un appel
    public function index(Request $request)
    {
        $uid = $request->user()->id;

        $enCours = $this->requeteBase()->where('c.livreur_id', $uid)->where('c.statut', 'EN_LIVRAISON')->get();
        $disponibles = $this->requeteBase()->whereNull('c.livreur_id')
            ->whereIn('c.statut', self::STATUTS_A_LIVRER)->orderBy('c.date_commande')->get();
        $historique = $this->requeteBase()->where('c.livreur_id', $uid)->where('c.statut', 'LIVREE')
            ->orderByDesc('c.date_livraison')->limit(10)->get();

        $livrees = DB::table('commandes')->where('livreur_id', $uid)->where('statut', 'LIVREE');

        return response()->json([
            'en_cours'    => $this->avecLignes($enCours)[0] ?? null,
            'disponibles' => $this->avecLignes($disponibles),
            'historique'  => $this->avecLignes($historique),
            'total_livrees' => (clone $livrees)->count(),
            'gains'         => (float) (clone $livrees)->sum('frais_livraison'),
        ]);
    }

    // POST /api/livraisons/{id}/accepter
    public function accepter(Request $request, int $id)
    {
        $uid = $request->user()->id;

        $refus = DB::transaction(function () use ($uid, $id) {
            // On verrouille la ligne du livreur : deux acceptations simultanées passent l'une après l'autre
            DB::table('users')->where('id', $uid)->lockForUpdate()->first();

            $deja = DB::table('commandes')->where('livreur_id', $uid)->where('statut', 'EN_LIVRAISON')->exists();
            if ($deja) {
                return ['code' => 'LIVRAISON_EN_COURS', 'message' => 'Terminez d\'abord votre livraison en cours (une seule à la fois).'];
            }

            $commande = DB::table('commandes')->where('id', $id)->lockForUpdate()->first();
            if (!$commande || $commande->livreur_id !== null || !in_array($commande->statut, self::STATUTS_A_LIVRER, true)) {
                return ['code' => 'COMMANDE_INDISPONIBLE', 'message' => 'Cette commande n\'est plus disponible.'];
            }

            DB::table('commandes')->where('id', $id)->update(['livreur_id' => $uid, 'statut' => 'EN_LIVRAISON']);
            return null;
        });

        if ($refus) {
            return response()->json($refus, 422);
        }
        return response()->json(['message' => 'Livraison acceptée']);
    }

    // POST /api/livraisons/{id}/terminer
    public function terminer(Request $request, int $id)
    {
        $uid = $request->user()->id;

        $modifiees = DB::table('commandes')
            ->where('id', $id)->where('livreur_id', $uid)->where('statut', 'EN_LIVRAISON')
            ->update(['statut' => 'LIVREE', 'date_livraison' => now()]);

        if (!$modifiees) {
            return response()->json(['code' => 'LIVRAISON_INTROUVABLE', 'message' => 'Aucune livraison en cours pour cette commande.'], 422);
        }
        return response()->json(['message' => 'Commande livrée']);
    }

    // GET /api/mes-commandes : suivi côté patient
    public function mesCommandes(Request $request)
    {
        $commandes = DB::table('commandes as c')
            ->join('pharmacies as p', 'p.id', '=', 'c.pharmacie_id')
            ->leftJoin('users as l', 'l.id', '=', 'c.livreur_id')
            ->where('c.patient_id', $request->user()->id)
            ->orderByDesc('c.id')
            ->select(
                'c.id', 'c.numero_commande', 'c.adresse_livraison', 'c.montant_total', 'c.statut',
                'c.date_commande', 'c.date_livraison',
                'p.nom as pharmacie_nom', 'l.name as livreur_nom'
            )->get();

        return response()->json($this->avecLignes($commandes));
    }
        // GET /api/pharmacien/commandes : commandes à préparer, prêtes ou en livraison
    public function commandesPharmacien()
    {
        $commandes = $this->requeteBase()
            ->whereIn('c.statut', array_merge(self::STATUTS_A_PREPARER, ['PRETE', 'EN_LIVRAISON']))
            ->orderByDesc('c.id')
            ->get();

        return response()->json($this->avecLignes($commandes));
    }

    // POST /api/pharmacien/commandes/{id}/prete : le pharmacien a préparé la commande
    public function marquerPrete(int $id)
    {
        $modifiees = DB::table('commandes')
            ->where('id', $id)
            ->whereIn('statut', self::STATUTS_A_PREPARER)
            ->update(['statut' => 'PRETE']);

        if (!$modifiees) {
            return response()->json(['code' => 'COMMANDE_INTROUVABLE', 'message' => 'Cette commande ne peut plus être marquée prête.'], 422);
        }
        return response()->json(['message' => 'Commande prête pour la livraison']);
    }
}