<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

// À lancer UNE SEULE FOIS sur un serveur vide, pour créer le premier compte administrateur.
// Ensuite, l'administrateur crée les pharmaciens et les livreurs depuis l'application.
//
//   php artisan compte:admin admin@pharmasante.sn MotDePasse2026
class CreerAdmin extends Command
{
    protected $signature = 'compte:admin {email} {mot_de_passe}';
    protected $description = 'Crée le premier compte administrateur';

    public function handle(): int
    {
        $email = $this->argument('email');
        $mdp = $this->argument('mot_de_passe');

        if (strlen($mdp) < 8) {
            $this->error('Le mot de passe doit contenir au moins 8 caractères.');
            return self::FAILURE;
        }
        if (User::where('email', $email)->exists()) {
            $this->error('Cet email existe déjà.');
            return self::FAILURE;
        }

        User::create([
            'name'     => 'Administrateur',
            'prenom'   => 'Administrateur',
            'nom'      => 'PharmaSanté',
            'email'    => $email,
            'password' => $mdp,
            'role'     => 'admin',
        ]);

        $this->info("Administrateur créé : $email");
        return self::SUCCESS;
    }
}