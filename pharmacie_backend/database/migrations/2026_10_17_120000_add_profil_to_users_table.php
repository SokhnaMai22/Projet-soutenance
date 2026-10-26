<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'prenom'))         $table->string('prenom')->nullable()->after('name');
            if (!Schema::hasColumn('users', 'nom'))            $table->string('nom')->nullable();
            if (!Schema::hasColumn('users', 'telephone'))      $table->string('telephone', 20)->nullable()->unique()->after('email');
            if (!Schema::hasColumn('users', 'date_naissance')) $table->date('date_naissance')->nullable();
            if (!Schema::hasColumn('users', 'sexe'))           $table->enum('sexe', ['homme', 'femme'])->nullable();
            if (!Schema::hasColumn('users', 'ville'))          $table->string('ville')->nullable();
            if (!Schema::hasColumn('users', 'adresse'))        $table->string('adresse')->nullable();
        });
    }

    public function down(): void
    {
        //
    }
};