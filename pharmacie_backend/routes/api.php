<?php

use App\Http\Controllers\AdminComptesController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\CommandeController;
use App\Http\Controllers\GestionCatalogueController;
use App\Http\Controllers\LivraisonController;
use App\Http\Controllers\MedicamentController;
use App\Http\Controllers\OrdonnanceController;
use Illuminate\Support\Facades\Route;

Route::post('/register', [AuthController::class, 'register']);
Route::post('/login',    [AuthController::class, 'login']);

// Catalogue public (consultable avant connexion)
Route::get('/medicaments', [MedicamentController::class, 'index']);
Route::get('/pharmacies',  [MedicamentController::class, 'pharmacies']);

Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me',      [AuthController::class, 'me']);
    Route::post('/logout', [AuthController::class, 'logout']);

    // Routes de test pour vérifier le contrôle des rôles
    Route::middleware('role:pharmacien')->get('/pharmacien/test', fn () => ['ok' => 'pharmacien']);
    Route::middleware('role:admin')->get('/admin/test', fn () => ['ok' => 'admin']);

    // Image d'une ordonnance : pharmacien, admin, ou patient propriétaire (contrôlé dans le contrôleur)
    Route::get('/ordonnances/{ordonnance}/image', [OrdonnanceController::class, 'image']);

    // Patient
    Route::middleware('role:patient')->group(function () {
        Route::post('/ordonnances', [OrdonnanceController::class, 'store']);
        Route::get('/mes-ordonnances', [OrdonnanceController::class, 'mesOrdonnances']);
        Route::post('/commande/verifier', [CommandeController::class, 'verifier']);
        Route::post('/commande', [CommandeController::class, 'store']);
        Route::get('/mes-commandes', [LivraisonController::class, 'mesCommandes']);
    });

    // Pharmacien : consulter, valider, rejeter, ajouter un médicament
    Route::middleware('role:pharmacien')->group(function () {
        Route::get('/ordonnances', [OrdonnanceController::class, 'index']);
        Route::post('/ordonnances/{ordonnance}/valider', [OrdonnanceController::class, 'valider']);
        Route::post('/medicaments', [MedicamentController::class, 'store']);
        Route::post('/ordonnances/{ordonnance}/rejeter', [OrdonnanceController::class, 'rejeter']);
        // Préparation des commandes
        Route::get('/pharmacien/commandes', [LivraisonController::class, 'commandesPharmacien']);
        Route::post('/pharmacien/commandes/{id}/prete', [LivraisonController::class, 'marquerPrete'])->whereNumber('id');
    });

    // Gestion du catalogue depuis l'application (pharmacien ou admin)
    Route::middleware('role:pharmacien,admin')->prefix('gestion')->group(function () {
        Route::get('/medicaments', [GestionCatalogueController::class, 'medicaments']);
        Route::put('/medicaments/{id}', [GestionCatalogueController::class, 'modifierMedicament'])->whereNumber('id');
        Route::post('/medicaments/{id}/indisponible', [GestionCatalogueController::class, 'rendreIndisponible'])->whereNumber('id');
        Route::delete('/medicaments/{id}', [GestionCatalogueController::class, 'supprimerMedicament'])->whereNumber('id');
        Route::post('/pharmacies', [GestionCatalogueController::class, 'creerPharmacie']);
        Route::post('/stocks', [GestionCatalogueController::class, 'definirStock']);
    });

    // Administrateur : création des comptes pharmacien et livreur
    Route::middleware('role:admin')->prefix('admin/comptes')->group(function () {
        Route::get('/', [AdminComptesController::class, 'index']);
        Route::post('/', [AdminComptesController::class, 'creer']);
    });

    // Livreur : courses disponibles, accepter, terminer
    Route::middleware('role:livreur')->group(function () {
        Route::get('/livraisons', [LivraisonController::class, 'index']);
        Route::post('/livraisons/{id}/accepter', [LivraisonController::class, 'accepter'])->whereNumber('id');
        Route::post('/livraisons/{id}/terminer', [LivraisonController::class, 'terminer'])->whereNumber('id');
    });
});