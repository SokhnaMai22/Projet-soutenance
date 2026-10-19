<?php

use App\Http\Controllers\MedicamentController;
use Illuminate\Support\Facades\Route;

// Page d'accueil Laravel
Route::get('/', function () {
    return view('welcome');
});

// Catalogue public (lecture seule) : médicaments avec stock et pharmacie
Route::get('/api/medicaments', [MedicamentController::class, 'index']);
Route::get('/api/pharmacies', [MedicamentController::class, 'pharmacies']);