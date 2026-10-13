<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\OrdonnanceController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me',      [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Routes de test pour vérifier le contrôle des rôles
    Route::middleware('role:pharmacien')->get('/pharmacien/test', fn () => ['ok' => 'pharmacien']);
    Route::middleware('role:admin')->get('/admin/test', fn () => ['ok' => 'admin']);

    // Patient : envoyer et consulter ses ordonnances
    Route::middleware('role:patient')->group(function () {
        Route::post('/ordonnances', [OrdonnanceController::class, 'store']);
        Route::get('/mes-ordonnances', [OrdonnanceController::class, 'mesOrdonnances']);
    });

    // Pharmacien : consulter, valider, rejeter
    Route::middleware('role:pharmacien')->group(function () {
        Route::get('/ordonnances', [OrdonnanceController::class, 'index']);
        Route::post('/ordonnances/{ordonnance}/valider', [OrdonnanceController::class, 'valider']);
        Route::post('/ordonnances/{ordonnance}/rejeter', [OrdonnanceController::class, 'rejeter']);
    });
});