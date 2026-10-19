<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('prenom')->nullable()->after('name');
            $table->string('nom')->nullable()->after('prenom');
            $table->string('telephone', 20)->nullable()->unique()->after('email');
            $table->date('date_naissance')->nullable();
            $table->enum('sexe', ['homme', 'femme'])->nullable();
            $table->string('ville')->nullable();
            $table->string('adresse')->nullable();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropUnique(['telephone']);
            $table->dropColumn(['prenom', 'nom', 'telephone', 'date_naissance', 'sexe', 'ville', 'adresse']);
        });
    }
};