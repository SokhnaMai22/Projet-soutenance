<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

/**
 * Catalogue de démonstration : pharmacies + médicaments + stocks.
 * Rejouable sans risque : met à jour ce qui existe déjà, n'efface rien.
 */
class MedicamentSeeder extends Seeder
{
    public function run(): void
    {
        // [nom, quartier, adresse, téléphone, pharmacien titulaire, fichier photo]
        $pharmacies = [
            ['Pharmacie Guigon',              'Plateau',   'Avenue Léopold Sédar Senghor', '33 000 00 01', 'Dr Awa Diop',      'guigon.jpg'],
            ['Pharmacie Cheikh Anta Diop',    'Fann',      'Avenue Cheikh Anta Diop',      '33 000 00 02', 'Dr Moussa Ndiaye', 'cheikh_anta_diop.jpg'],
            ['Pharmacie de la Nation',        'Médina',    'Rue 22 x 15',                  '33 000 00 03', 'Dr Fatou Sarr',    'nation.jpg'],
            ['Pharmacie Mame Diarra',         'Parcelles', 'Unité 15, Parcelles Assainies','33 000 00 04', 'Dr Cheikh Ba',     'mame_diarra.jpg'],
        ];

        $idsPharmacies = [];
        foreach ($pharmacies as [$nom, $quartier, $adresse, $tel, $pharmacien, $photo]) {
            $existant = DB::table('pharmacies')->where('nom', $nom)->value('id');
            $valeurs = [
                'quartier' => $quartier, 'adresse' => $adresse, 'telephone' => $tel,
                'ville' => 'Dakar', 'statut' => 'ACTIVE',
                'pharmacien_nom' => $pharmacien, 'photo' => $photo,
            ];
            if ($existant) {
                DB::table('pharmacies')->where('id', $existant)->update($valeurs);
                $idsPharmacies[] = $existant;
            } else {
                $idsPharmacies[] = DB::table('pharmacies')->insertGetId(['nom' => $nom] + $valeurs);
            }
        }

        // [mot-clé de recherche, nom affiché, description, forme, dosage, prix, ordonnance ?, image, catégorie]
        $medicaments = [
            ['Paracétamol',   'Paracétamol (Doliprane)', 'Soulage les douleurs légères et la fièvre.',                'Comprimé',               '1000 mg',   1500, 0, 'doliprane.jpg',     'Douleur & fièvre'],
            ['Ibuprofène',    'Ibuprofène',              'Anti-inflammatoire contre douleurs, règles douloureuses, fièvre.', 'Comprimé',          '400 mg',    1800, 0, 'ibuprofene.jpg',    'Douleur & fièvre'],
            ['Aspirine',      'Aspirine',                'Antalgique et antipyrétique.',                              'Comprimé',               '500 mg',    1200, 0, 'aspirine.jpg',      'Douleur & fièvre'],
            ['Tramadol',      'Tramadol',                'Antalgique puissant, uniquement sur prescription.',         'Gélule',                 '50 mg',     4200, 1, 'tramadol.jpg',      'Douleur & fièvre'],

            ['Amoxicilline',  'Amoxicilline',            'Antibiotique à large spectre.',                             'Gélule',                 '500 mg',    3200, 1, 'amoxicilline.jpg',  'Antibiotiques'],
            ['Azithromycine', 'Azithromycine',           'Antibiotique pour infections respiratoires et ORL.',        'Comprimé',               '500 mg',    5500, 1, 'azithromycine.jpg', 'Antibiotiques'],
            ['Ciprofloxacine','Ciprofloxacine',          'Antibiotique pour infections urinaires et digestives.',     'Comprimé',               '500 mg',    4800, 1, 'ciprofloxacine.jpg','Antibiotiques'],
            ['Métronidazole', 'Métronidazole (Flagyl)',  'Antibiotique et antiparasitaire.',                          'Comprimé',               '500 mg',    2600, 1, 'metronidazole.jpg', 'Antibiotiques'],

            ['Coartem',       'Coartem',                 'Traitement du paludisme simple (artéméther + luméfantrine).','Comprimé',              '20/120 mg', 3500, 1, 'coartem.jpg',       'Paludisme'],
            ['Paracétamol enfant', 'Paracétamol sirop enfant', 'Fièvre et douleurs de l\'enfant.',                    'Sirop',                  '120 mg/5 ml',1900,0, 'sirop_paracetamol.jpg','Douleur & fièvre'],

            ['Vitamine C',    'Vitamine C 1000',         'Complément pour réduire la fatigue.',                       'Comprimé effervescent',  '1000 mg',   2500, 0, 'vitamine_c.jpg',    'Vitamines'],
            ['Fer',           'Fer + Acide folique',     'Prévention et traitement de l\'anémie.',                    'Comprimé',               '60 mg',     3000, 0, 'fer_folique.jpg',   'Vitamines'],
            ['Magnésium',     'Magnésium B6',            'Réduit la fatigue, le stress et les crampes.',              'Comprimé',               '300 mg',    2800, 0, 'magnesium.jpg',     'Vitamines'],

            ['Spasfon',       'Spasfon',                 'Douleurs spasmodiques de l\'estomac et de l\'intestin.',    'Comprimé',               '80 mg',     2100, 0, 'spasfon.jpg',       'Digestion'],
            ['Smecta',        'Smecta',                  'Traitement des diarrhées.',                                 'Sachet',                 '3 g',       2300, 0, 'smecta.jpg',        'Digestion'],
            ['Oméprazole',    'Oméprazole',              'Réduit l\'acidité gastrique (reflux, ulcère).',             'Gélule',                 '20 mg',     3000, 1, 'omeprazole.jpg',    'Digestion'],
            ['SRO',           'SRO (réhydratation orale)','Prévient la déshydratation lors des diarrhées.',           'Sachet',                 '1 sachet',   500, 0, 'sro.jpg',           'Digestion'],

            ['Loratadine',    'Loratadine',              'Antihistaminique contre rhume des foins et allergies.',     'Comprimé',               '10 mg',     1700, 0, 'loratadine.jpg',    'Allergies & rhume'],
            ['Cétirizine',    'Cétirizine',              'Antihistaminique : urticaire, allergies.',                  'Comprimé',               '10 mg',     1600, 0, 'cetirizine.jpg',    'Allergies & rhume'],
            ['Sirop toux',    'Sirop contre la toux',    'Apaise la toux grasse, fluidifie les sécrétions.',          'Sirop',                  '100 ml',    3200, 0, 'sirop_toux.jpg',    'Allergies & rhume'],

            ['Bétadine',      'Bétadine solution',       'Antiseptique pour plaies et petites blessures.',            'Solution',               '10 %',      1900, 0, 'betadine.jpg',      'Soins & hygiène'],
            ['Sérum',         'Sérum physiologique',     'Lavage des yeux, du nez et des plaies.',                    'Unidoses',               '5 ml x 20', 1100, 0, 'serum_physio.jpg',  'Soins & hygiène'],
            ['Biafine',       'Biafine crème',           'Brûlures légères et coups de soleil.',                      'Crème',                  '93 g',      3400, 0, 'biafine.jpg',       'Soins & hygiène'],

            ['Metformine',    'Metformine',              'Traitement du diabète de type 2.',                          'Comprimé',               '500 mg',    2000, 1, 'metformine.jpg',    'Maladies chroniques'],
            ['Amlodipine',    'Amlodipine',              'Traitement de l\'hypertension artérielle.',                 'Comprimé',               '5 mg',      2400, 1, 'amlodipine.jpg',    'Maladies chroniques'],
            ['Salbutamol',    'Salbutamol spray',        'Soulage la crise d\'asthme.',                               'Aérosol',                '100 µg',    3800, 1, 'salbutamol.jpg',    'Maladies chroniques'],
        ];

        foreach ($medicaments as $i => [$cle, $nom, $desc, $forme, $dosage, $prix, $ordo, $image, $categorie]) {
            // On réutilise une ligne existante (même début de nom) pour ne pas créer de doublon
            $id = DB::table('medicaments')->where('nom', $nom)->value('id')
                ?? DB::table('medicaments')->where('nom', 'like', $cle . '%')->where('nom', 'not like', '%enfant%')->value('id');

            $valeurs = [
                'nom' => $nom, 'description' => $desc, 'forme' => $forme, 'dosage' => $dosage,
                'prix' => $prix, 'necessite_ordonnance' => $ordo,
                'image' => $image, 'categorie' => $categorie,
            ];

            if ($id) {
                DB::table('medicaments')->where('id', $id)->update($valeurs);
            } else {
                $id = DB::table('medicaments')->insertGetId($valeurs);
            }

            // Chaque médicament est disponible dans deux pharmacies
            foreach ([0, 1] as $decalage) {
                $pharmacieId = $idsPharmacies[($i + $decalage) % count($idsPharmacies)];
                $cond = ['pharmacie_id' => $pharmacieId, 'medicament_id' => $id];
                $quantite = $decalage === 0 ? 30 + (($i * 7) % 40) : 10 + (($i * 5) % 20);
                if (DB::table('stocks')->where($cond)->exists()) {
                    DB::table('stocks')->where($cond)->update(['quantite_disponible' => $quantite]);
                } else {
                    DB::table('stocks')->insert($cond + ['quantite_disponible' => $quantite]);
                }
            }
        }
    }
}