<?php

namespace App\Http\Controllers;

use App\Models\Ordonnance;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
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

    public function valider(Request $request, Ordonnance $ordonnance)
    {
        $ordonnance->update([
            'statut'        => 'VALIDEE',
            'pharmacien_id' => $request->user()->id,
            'motif_rejet'   => null,
        ]);
        return $ordonnance;
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