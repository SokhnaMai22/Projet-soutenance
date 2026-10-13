<?php

use Illuminate\Support\Facades\Route;
use Illuminate\Support\Facades\DB;

// Page d'accueil Laravel
Route::get('/', function () {
    return view('welcome');
});

// 1. API : Liste des médicaments depuis MySQL (avec DB::table)
Route::get('/api/medicaments', function () {
    return response()->json(DB::table('medicaments')->get());
});

// 2. API : Liste des pharmacies de Dakar
Route::get('/api/pharmacies', function () {
    return response()->json(DB::table('pharmacies')->get());
});

// 3. API : Enregistrement de commande avec paiement Wave / OM
Route::post('/api/commandes', function () {
    $commandeId = DB::table('commandes')->insertGetId([
        'numero_commande' => 'CMD-' . strtoupper(uniqid()),
        'patient_id' => 1,
        'pharmacie_id' => 1,
        'adresse_livraison' => 'Dakar, Médina Rue 22',
        'montant_medicaments' => 3000,
        'frais_livraison' => 1000.00,
        'montant_total' => 4000,
        'statut' => 'PAYEE',
    ]);

    DB::table('paiements')->insert([
        'commande_id' => $commandeId,
        'moyen' => 'WAVE',
        'reference_transaction' => 'TX-' . strtoupper(uniqid()),
        'numero_telephone' => '771234567',
        'montant' => 4000,
        'statut' => 'REUSSI',
    ]);

    return response()->json([
        'succes' => true,
        'message' => 'Commande et paiement Wave enregistrés dans MySQL !',
        'commande_id' => $commandeId,
    ]);
    // 1. API Médicaments avec toutes les autorisations du navigateur
Route::get('/api/medicaments', function () {
    return response()->json(DB::table('medicaments')->get())
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        ->header('Access-Control-Allow-Headers', '*');
});
});