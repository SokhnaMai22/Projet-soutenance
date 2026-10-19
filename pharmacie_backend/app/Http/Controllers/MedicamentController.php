<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;

class MedicamentController extends Controller
{
    // GET /api/medicaments : catalogue public (une ligne par médicament, pharmacie la mieux approvisionnée)
    public function index()
    {
        $lignes = DB::table('medicaments as m')
            ->join('stocks as s', 's.medicament_id', '=', 'm.id')
            ->join('pharmacies as p', 'p.id', '=', 's.pharmacie_id')
            ->where('p.statut', 'ACTIVE')
            ->select(
                'm.id', 'm.nom', 'm.description', 'm.forme', 'm.dosage', 'm.prix',
                'm.necessite_ordonnance', 'm.image', 'm.categorie',
                'p.id as pharmacie_id', 'p.nom as pharmacie_nom', 'p.quartier as pharmacie_quartier',
                'p.pharmacien_nom', 'p.photo as pharmacie_photo',
                's.quantite_disponible as stock'
            )
            ->orderByDesc('s.quantite_disponible')
            ->get();

        return $lignes->groupBy('id')->map(fn ($g) => $g->first())->sortBy('nom')->values();
    }

    // GET /api/pharmacies : pharmacies partenaires
    public function pharmacies()
    {
        return DB::table('pharmacies')
            ->where('statut', 'ACTIVE')
            ->select('id', 'nom', 'quartier', 'adresse', 'telephone', 'pharmacien_nom', 'photo')
            ->orderBy('nom')
            ->get();
    }
}