<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

// Création des comptes professionnels (pharmacien, livreur) par l'administrateur, depuis l'application.
// L'inscription publique ne crée que des patients : un inconnu ne peut donc pas devenir pharmacien.
class AdminComptesController extends Controller
{
    // GET /api/admin/comptes : comptes pharmacien et livreur existants
    public function index()
    {
        return User::whereIn('role', ['pharmacien', 'livreur'])
            ->orderBy('role')
            ->orderBy('name')
            ->get(['id', 'name', 'email', 'telephone', 'role']);
    }

    // POST /api/admin/comptes
    public function creer(Request $request)
    {
        $data = $request->validate([
            'prenom'    => 'required|string|max:100',
            'nom'       => 'required|string|max:100',
            'email'     => 'required|email|max:255|unique:users',
            'telephone' => ['required', 'regex:/^(\+?221)?\s?(7[05678]|33)(\s?\d){7}$/', 'unique:users'],
            'password'  => 'required|string|min:8|regex:/[A-Za-z]/|regex:/\d/',
            'role'      => ['required', Rule::in(['pharmacien', 'livreur'])],
        ], [
            'telephone.regex'  => 'Numéro de téléphone invalide (ex : 77 123 45 67)',
            'telephone.unique' => 'Ce numéro est déjà utilisé',
            'email.unique'     => 'Cet email est déjà utilisé',
            'password.min'     => 'Le mot de passe doit contenir au moins 8 caractères',
            'password.regex'   => 'Le mot de passe doit contenir des lettres et des chiffres',
            'role.in'          => 'Le rôle doit être pharmacien ou livreur',
        ]);

        $user = User::create([
            'name'      => trim($data['prenom'] . ' ' . $data['nom']),
            'prenom'    => $data['prenom'],
            'nom'       => $data['nom'],
            'email'     => $data['email'],
            'telephone' => preg_replace('/\s+/', '', $data['telephone']),
            'password'  => $data['password'],
            'role'      => $data['role'],
        ]);

        return response()->json([
            'message' => 'Compte ' . $data['role'] . ' créé',
            'id'      => $user->id,
        ], 201);
    }
}