#!/bin/bash

for i in {1..10}
do
    # Chemin vers ton fichier de score VirSorter2
    input="/srv/scratch/alamiex/jeux_de_données/output_virsorter2/rep${i}/final-viral-score.tsv"
    output="virsorter2_results_rep${i}_simple.csv"
    
    echo "Extraction VirSorter2 réplicat $i..."
    
    # Correction du split : on utilise \\|\\| pour échapper les barres verticales
    awk -F'\t' 'BEGIN {OFS=","; print "ID_Sequence,Prediction_VirSorter2"} 
    NR>1 {
        split($1, a, "\\|\\|");
        clean_id = a[1];
        
        # Logique de prédiction (Score >= 0.5 ou Hallmark >= 1)
        if ($4 >= 0.5 || $7 >= 1) {
            pred = "Virus"
        } else {
            pred = "Autre"
        }
        print clean_id, pred
    }' "$input" > "$output"
done