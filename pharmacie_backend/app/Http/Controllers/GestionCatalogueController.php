<?php

namespace App\Http\Controllers;

use Illuminate\Database\QueryException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

// Gestion du catalogue depuis l'application (pharmacien / admin).
// L'AJOUT d'un médicament (avec photo et stock) est fait par MedicamentController@store
// (POST /api/medicaments). Ici : pharmacies, stocks, modification, indisponibilité, suppression.
class GestionCatalogueController extends Controller
{
    // GET /api/gestion/medicaments : tous les médicaments (même sans stock) avec leur stock total
    public function medicaments()
    {
        $colonnes = ['m.id', 'm.nom', 'm.description', 'm.dosage', 'm.forme', 'm.prix',
                     'm.necessite_ordonnance', 'm.image'];
        if (Schema::hasColumn('medicaments', 'categorie')) {
            $colonnes[] = 'm.categorie';
        }
        $colonnes[] = DB::raw('COALESCE((SELECT SUM(s.quantite_disponible) FROM stocks s WHERE s.medicament_id = m.id), 0) AS stock_total');

        return DB::table('medicaments as m')->select($colonnes)->orderBy('m.nom')->get();
    }

    // PUT /api/gestion/medicaments/{id} : modifier prix, description (et ordonnance)
    public function modifierMedicament(Request $request, int $id)
    {
        if (!DB::table('medicaments')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Médicament introuvable'], 404);
        }

        $data = $request->validate([
            'prix'                 => 'sometimes|required|integer|min:0',
            'description'          => 'sometimes|nullable|string|max:1000',
            'necessite_ordonnance' => 'sometimes|required|boolean',
        ]);

        $maj = [];
        if (array_key_exists('prix', $data)) $maj['prix'] = $data['prix'];
        if (array_key_exists('description', $data)) $maj['description'] = $data['description'] ?? '';
        if (array_key_exists('necessite_ordonnance', $data)) {
            $maj['necessite_ordonnance'] = $request->boolean('necessite_ordonnance') ? 1 : 0;
        }
        if (empty($maj)) {
            return response()->json(['message' => 'Rien à modifier'], 422);
        }

        DB::table('medicaments')->where('id', $id)->update($maj);
        return response()->json(['message' => 'Médicament modifié'], 200);
    }

    // POST /api/gestion/medicaments/{id}/indisponible : stock à 0 partout (il disparaît du catalogue)
    public function rendreIndisponible(int $id)
    {
        if (!DB::table('medicaments')->where('id', $id)->exists()) {
            return response()->json(['message' => 'Médicament introuvable'], 404);
        }
        DB::table('stocks')->where('medicament_id', $id)->update(['quantite_disponible' => 0]);
        return response()->json(['message' => 'Médicament marqué indisponible'], 200);
    }

    // DELETE /api/gestion/medicaments/{id}
    public function supprimerMedicament(int $id)
    {
        $med = DB::table('medicaments')->where('id', $id)->first();
        if (!$med) {
            return response()->json(['message' => 'Médicament introuvable'], 404);
        }

        try {
            DB::transaction(function () use ($id) {
                DB::table('stocks')->where('medicament_id', $id)->delete();
                DB::table('medicaments')->where('id', $id)->delete();
            });
        } catch (QueryException $e) {
            return response()->json([
                'message' => 'Ce médicament figure dans des commandes ou ordonnances : marquez-le indisponible au lieu de le supprimer',
            ], 409);
        }

        if (!empty($med->image)) {
            $chemin = public_path('images/medicaments/' . basename($med->image));
            if (is_file($chemin)) @unlink($chemin);
        }
        return response()->json(['message' => 'Médicament supprimé'], 200);
    }

    // POST /api/gestion/pharmacies
    public function creerPharmacie(Request $request)
    {
        $data = $request->validate([
            'nom'            => 'required|string|max:150',
            'quartier'       => 'nullable|string|max:100',
            'adresse'        => 'nullable|string|max:200',
            'telephone'      => 'nullable|string|max:30',
            'pharmacien_nom' => 'nullable|string|max:100',
        ]);

        if (DB::table('pharmacies')->where('nom', $data['nom'])->exists()) {
            return response()->json(['message' => 'Cette pharmacie existe déjà'], 422);
        }

        $ligne = [
            'nom'       => $data['nom'],
            'quartier'  => $data['quartier'] ?? '',
            'adresse'   => $data['adresse'] ?? '',
            'telephone' => $data['telephone'] ?? '',
            'ville'     => 'Dakar',
            'statut'    => 'ACTIVE',
        ];
        if (Schema::hasColumn('pharmacies', 'pharmacien_nom')) $ligne['pharmacien_nom'] = $data['pharmacien_nom'] ?? '';
        if (Schema::hasColumn('pharmacies', 'photo')) $ligne['photo'] = '';

        $id = DB::table('pharmacies')->insertGetId($ligne);
        return response()->json(['message' => 'Pharmacie ajoutée', 'id' => $id], 201);
    }

    // POST /api/gestion/stocks : fixe la quantité d'un médicament dans une pharmacie
    public function definirStock(Request $request)
    {
        $data = $request->validate([
            'pharmacie_id'  => 'required|integer|exists:pharmacies,id',
            'medicament_id' => 'required|integer|exists:medicaments,id',
            'quantite'      => 'required|integer|min:0|max:100000',
        ]);

        DB::table('stocks')->updateOrInsert(
            ['pharmacie_id' => $data['pharmacie_id'], 'medicament_id' => $data['medicament_id']],
            ['quantite_disponible' => $data['quantite']]
        );

        return response()->json(['message' => 'Stock enregistré'], 200);
    }
}