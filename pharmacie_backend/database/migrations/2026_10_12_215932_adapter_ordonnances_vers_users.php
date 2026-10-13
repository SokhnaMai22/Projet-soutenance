<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // ordonnances.patient_id : utilisateurs -> users
        DB::statement('ALTER TABLE ordonnances DROP FOREIGN KEY ordonnances_ibfk_1');
        DB::statement('ALTER TABLE ordonnances MODIFY patient_id BIGINT UNSIGNED NOT NULL');
        DB::statement('ALTER TABLE ordonnances ADD CONSTRAINT ordonnances_patient_users_fk FOREIGN KEY (patient_id) REFERENCES users(id)');

        // ordonnances.pharmacien_id : nouveau, lié à users
        DB::statement('ALTER TABLE ordonnances ADD COLUMN pharmacien_id BIGINT UNSIGNED NULL');
        DB::statement('ALTER TABLE ordonnances ADD CONSTRAINT ordonnances_pharmacien_users_fk FOREIGN KEY (pharmacien_id) REFERENCES users(id)');

        // commandes.patient_id : utilisateurs -> users
        DB::statement('ALTER TABLE commandes DROP FOREIGN KEY commandes_ibfk_1');
        DB::statement('ALTER TABLE commandes MODIFY patient_id BIGINT UNSIGNED NOT NULL');
        DB::statement('ALTER TABLE commandes ADD CONSTRAINT commandes_patient_users_fk FOREIGN KEY (patient_id) REFERENCES users(id)');
    }

    public function down(): void
    {
        //
    }
};