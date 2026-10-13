<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $comptes = [
            ['Patient Test',    'patient@test.sn',    'patient'],
            ['Pharmacien Test', 'pharmacien@test.sn', 'pharmacien'],
            ['Livreur Test',    'livreur@test.sn',    'livreur'],
            ['Admin Test',      'admin@test.sn',      'admin'],
        ];

        foreach ($comptes as [$nom, $email, $role]) {
            User::updateOrCreate(
                ['email' => $email],
                ['name' => $nom, 'password' => 'password123', 'role' => $role]
            );
        }
    }
}