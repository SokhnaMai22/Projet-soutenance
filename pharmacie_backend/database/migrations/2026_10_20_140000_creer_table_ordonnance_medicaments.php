<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('ordonnance_medicaments', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('ordonnance_id');
            $table->unsignedBigInteger('medicament_id');
            $table->unsignedInteger('quantite_max')->default(1);
            $table->unique(['ordonnance_id', 'medicament_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ordonnance_medicaments');
    }
};