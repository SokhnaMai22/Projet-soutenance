<?php

namespace App\Http\Controllers;

use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

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
    // POST /api/medicaments : ajout d'un médicament (pharmacien)
public function store(Request $request)
{
    $data = $request->validate([
        'nom'                  => 'required|string|max:150',
        'description'          => 'nullable|string',
        'forme'                => 'required|string|max:50',
        'dosage'               => 'required|string|max:50',
        'prix'                 => 'required|numeric|min:0',
        'necessite_ordonnance' => 'required|boolean',
        'categorie'            => 'nullable|string|max:100',
        'quantite'             => 'required|integer|min:0',
        'pharmacie_id'         => 'nullable|integer|exists:pharmacies,id',
        'image'                => 'nullable|image|mimes:jpg,jpeg,png,webp|max:2048',
    ], [
        'nom.required'   => 'Le nom est obligatoire.',
        'forme.required' => 'La forme est obligatoire.',
        'dosage.required' => 'Le dosage est obligatoire.',
        'prix.required'  => 'Le prix est obligatoire.',
        'prix.numeric'   => 'Le prix doit être un nombre.',
        'quantite.required' => 'La quantité en stock est obligatoire.',
        'image.image'    => 'Le fichier doit être une image.',
        'image.max'      => 'La photo ne doit pas dépasser 2 Mo.',
    ]);

    $pharmacieId = $data['pharmacie_id']
        ?? DB::table('pharmacies')->where('statut', 'ACTIVE')->value('id');
    if (!$pharmacieId) {
        return response()->json(['message' => 'Aucune pharmacie active.'], 422);
    }

    $fichier = null;
    if ($request->hasFile('image')) {
        $fichier = Str::slug($data['nom']) . '-' . time() . '.' . $request->file('image')->extension();
        $request->file('image')->move(public_path('images/medicaments'), $fichier);
    }

    $id = DB::transaction(function () use ($data, $fichier, $pharmacieId) {
        $ligne = [
            'nom'                  => $data['nom'],
            'description'          => $data['description'] ?? '',
            'forme'                => $data['forme'],
            'dosage'               => $data['dosage'],
            'prix'                 => $data['prix'],
            'necessite_ordonnance' => $data['necessite_ordonnance'] ? 1 : 0,
            'image'                => $fichier,
        ];
        if (\Illuminate\Support\Facades\Schema::hasColumn('medicaments', 'categorie')) {
            $ligne['categorie'] = $data['categorie'] ?? 'Autres';
        }
        $medId = DB::table('medicaments')->insertGetId($ligne);

        DB::table('stocks')->insert([
            'medicament_id'       => $medId,
            'pharmacie_id'        => $pharmacieId,
            'quantite_disponible' => $data['quantite'],
        ]);

        return $medId;
    });

    return response()->json(['message' => 'Médicament ajouté.', 'id' => $id], 201);
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