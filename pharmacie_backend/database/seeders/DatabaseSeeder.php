<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $comptes = [
            ['Awa Diop',         'awa.diop@patient.sn',      'patient'],
            ['Moussa Ba',        'moussa.ba@patient.sn',     'patient'],
            ['Dr Fatou Sow',     'fatou.sow@pharmacien.sn',  'pharmacien'],
            ['Cheikh Ndiaye',    'cheikh@livreur.sn',        'livreur'],
            ['Administrateur',   'admin@pharmasante.sn',     'admin'],
        ];

        foreach ($comptes as [$nom, $email, $role]) {
            User::updateOrCreate(
                ['email' => $email],
                ['name' => $nom, 'password' => 'Pharma2026!', 'role' => $role]
            );
        }

        $this->call(MedicamentSeeder::class);
    }
}