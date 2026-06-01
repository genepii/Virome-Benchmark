#!/bin/bash

for i in {1..10}
do
    # 1. Chemins d'entrée et de sortie
    # On cible le fichier summary dans chaque dossier rep
    input="rep${i}/final_prediction/final_prediction_summary.tsv"
    output="phabox_results_rep${i}_simple.csv"
    
    echo "Traitement de PhaBox réplicat $i..."
    
    # 2. Extraction avec AWK
    # On vérifie la 3ème colonne (Pred)
    awk -F'\t' 'BEGIN {OFS=","; print "ID_Sequence,Prediction_PhaBox"} 
    NR>1 {
        # Si la colonne 3 est exactement "virus", on écrit Virus, sinon Autre
        if ($3 == "virus") {
            pred = "Virus"
        } else {
            pred = "Autre"
        }
        print $1, pred
    }' "$input" > "$output"
done