<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('medicaments', function (Blueprint $t) {
            if (!Schema::hasColumn('medicaments', 'image'))     $t->string('image', 100)->nullable();
            if (!Schema::hasColumn('medicaments', 'categorie')) $t->string('categorie', 60)->nullable();
        });

        Schema::table('pharmacies', function (Blueprint $t) {
            if (!Schema::hasColumn('pharmacies', 'photo'))          $t->string('photo', 100)->nullable();
            if (!Schema::hasColumn('pharmacies', 'pharmacien_nom')) $t->string('pharmacien_nom', 100)->nullable();
        });

        if (!Schema::hasColumn('commandes', 'livreur_id')) {
            DB::statement('ALTER TABLE commandes ADD COLUMN livreur_id BIGINT UNSIGNED NULL');
            DB::statement('ALTER TABLE commandes ADD CONSTRAINT commandes_livreur_users_fk FOREIGN KEY (livreur_id) REFERENCES users(id)');
        }
        if (!Schema::hasColumn('commandes', 'date_livraison')) {
            DB::statement('ALTER TABLE commandes ADD COLUMN date_livraison TIMESTAMP NULL DEFAULT NULL');
        }
    }

    public function down(): void
    {
        //
    }
};