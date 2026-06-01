#!/bin/bash

for i in {1..10}
do
    # 1. Chemins d'entrée et de sortie
    input="rep${i}/result_viraLM_rep${i}.csv"
    output="viraLM_results_rep${i}_simple.csv"
    
    echo "Traitement de ViraLM réplicat $i..."
    
    # 2. Extraction avec AWK
    # Le fichier est déjà un CSV (virgule), on vérifie le score en colonne 3
    awk -F',' 'BEGIN {OFS=","; print "ID_Sequence,Prediction_ViraLM"} 
    NR>1 {
        # Si le score en colonne 3 est >= 0.5 -> Virus, sinon Autre
        pred = ($3 >= 0.5) ? "Virus" : "Autre";
        print $1, pred
    }' "$input" > "$output"
done