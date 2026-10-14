<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Route;

// Page d'accueil Laravel
Route::get('/', function () {
    return view('welcome');
});

// Catalogue public (lecture seule)
Route::get('/api/medicaments', function () {
    return response()->json(DB::table('medicaments')->get());
});

Route::get('/api/pharmacies', function () {
    return response()->json(DB::table('pharmacies')->get());
});