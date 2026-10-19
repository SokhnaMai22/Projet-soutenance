<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    // L'inscription publique ne crée que des patients
        // L'inscription publique ne crée que des patients
        // L'inscription publique ne crée que des patients
    public function register(Request $request)
    {
        $data = $request->validate([
            'prenom'    => 'required|string|max:100',
            'nom'       => 'required|string|max:100',
            'email'     => 'required|email|max:255|unique:users',
            // Numéro sénégalais : 77/78/76/70/75/33 + 7 chiffres (indicatif +221 facultatif)
            'telephone' => ['required', 'regex:/^(\+?221)?\s?(7[05678]|33)(\s?\d){7}$/', 'unique:users'],
            'password'  => 'required|string|min:8|confirmed|regex:/[A-Za-z]/|regex:/\d/',
        ], [
            'telephone.regex'    => 'Numéro de téléphone invalide (ex : 77 123 45 67)',
            'telephone.unique'   => 'Ce numéro est déjà utilisé',
            'email.unique'       => 'Cet email est déjà utilisé',
            'password.min'       => 'Le mot de passe doit contenir au moins 8 caractères',
            'password.confirmed' => 'Les mots de passe ne correspondent pas',
            'password.regex'     => 'Le mot de passe doit contenir des lettres et des chiffres',
        ]);

        $user = User::create([
            'name'      => trim($data['prenom'] . ' ' . $data['nom']),
            'prenom'    => $data['prenom'],
            'nom'       => $data['nom'],
            'email'     => $data['email'],
            'telephone' => preg_replace('/\s+/', '', $data['telephone']),
            'password'  => $data['password'],
            'role'      => 'patient',
        ]);

        return response()->json([
            'user'  => $user,
            'token' => $user->createToken('mobile')->plainTextToken,
        ], 201);
    }

    public function login(Request $request)
    {
        $data = $request->validate([
            'email'    => 'required|email',
            'password' => 'required|string',
        ]);

        if (!Auth::attempt($data)) {
            return response()->json(['message' => 'Identifiants incorrects'], 401);
        }

        $user = Auth::user();

        return response()->json([
            'user'  => $user,
            'token' => $user->createToken('mobile')->plainTextToken,
        ]);
    }

    public function me(Request $request)
    {
        return $request->user();
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();
        return response()->json(['message' => 'Déconnecté']);
    }
}