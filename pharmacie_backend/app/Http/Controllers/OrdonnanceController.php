<?php

namespace App\Http\Controllers;

use App\Models\Ordonnance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class OrdonnanceController extends Controller
{
    public function store(Request $request)
    {
        $request->validate([
            'image'        => 'required|image|mimes:jpg,jpeg,png|max:4096',
            'note'         => 'nullable|string|max:500',
            'pharmacie_id' => 'nullable|integer|exists:pharmacies,id',
        ]);

        $path = $request->file('image')->store('ordonnances', 'public');

        $ordonnance = Ordonnance::create([
            'numero_ordonnance' => 'ORD-' . strtoupper(Str::random(6)),
            'patient_id'        => $request->user()->id,
            'pharmacie_id'      => $request->pharmacie_id ?? DB::table('pharmacies')->value('id'),
            'fichier_url'       => $path,
            'note_patient'      => $request->note,
            'statut'            => 'EN_ATTENTE',
        ]);

        return response()->json($ordonnance->fresh(), 201);
    }

    public function mesOrdonnances(Request $request)
    {
        return Ordonnance::where('patient_id', $request->user()->id)
            ->orderByDesc('date_envoi')->get();
    }

    public function index()
    {
        return Ordonnance::with('patient:id,name')->orderByDesc('date_envoi')->get();
    }

    // GET /api/ordonnances/{id}/image : l'image n'est servie qu'au pharmacien, à l'admin
    // et au patient propriétaire (donnée de santé : pas d'URL publique devinable)
    public function image(Request $request, Ordonnance $ordonnance)
    {
        $user = $request->user();

        $autorise = in_array($user->role, ['pharmacien', 'admin'], true)
            || ($user->role === 'patient' && (int) $ordonnance->patient_id === (int) $user->id);

        if (!$autorise) {
            abort(403, 'Accès refusé.');
        }
        if (!$ordonnance->fichier_url || !Storage::disk('public')->exists($ordonnance->fichier_url)) {
            abort(404, 'Image introuvable.');
        }

        return Storage::disk('public')->response($ordonnance->fichier_url);
    }

        public function valider(Request $request, Ordonnance $ordonnance)
    {
        // Le pharmacien indique les médicaments (et quantités maximales) que l'ordonnance autorise
        $data = $request->validate([
            'medicaments'                 => 'required|array|min:1',
            'medicaments.*.medicament_id' => 'required|integer|exists:medicaments,id',
            'medicaments.*.quantite'      => 'required|integer|min:1|max:99',
        ]);

        $autorises = [];
        foreach ($data['medicaments'] as $m) {
            $id = (int) $m['medicament_id'];
            $autorises[$id] = ($autorises[$id] ?? 0) + (int) $m['quantite'];
        }

        DB::transaction(function () use ($request, $ordonnance, $autorises) {
            $ordonnance->update([
                'statut'        => 'VALIDEE',
                'pharmacien_id' => $request->user()->id,
                'motif_rejet'   => null,
            ]);

            DB::table('ordonnance_medicaments')->where('ordonnance_id', $ordonnance->id)->delete();
            foreach ($autorises as $medicamentId => $quantite) {
                DB::table('ordonnance_medicaments')->insert([
                    'ordonnance_id' => $ordonnance->id,
                    'medicament_id' => $medicamentId,
                    'quantite_max'  => $quantite,
                ]);
            }
        });

        return $ordonnance->fresh();
    }

    public function rejeter(Request $request, Ordonnance $ordonnance)
    {
        $data = $request->validate(['motif' => 'required|string|max:500']);

        $ordonnance->update([
            'statut'        => 'REJETEE',
            'pharmacien_id' => $request->user()->id,
            'motif_rejet'   => $data['motif'],
        ]);
        return $ordonnance;
    }
}