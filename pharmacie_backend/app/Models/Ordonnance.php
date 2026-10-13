<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Ordonnance extends Model
{
    protected $table = 'ordonnances';
    public $timestamps = false;

    protected $fillable = [
        'numero_ordonnance', 'patient_id', 'pharmacie_id', 'pharmacien_id',
        'fichier_url', 'note_patient', 'statut', 'motif_rejet',
    ];

    public function patient()
    {
        return $this->belongsTo(User::class, 'patient_id');
    }

    public function pharmacien()
    {
        return $this->belongsTo(User::class, 'pharmacien_id');
    }
}