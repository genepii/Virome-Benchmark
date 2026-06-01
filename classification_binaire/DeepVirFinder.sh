for i in {1..10}
do
    # On adapte le chemin selon ton arborescence
    input="rep${i}/dataset_final_rep${i}.fasta_gt300bp_dvfpred.txt"
    output="DVF_results_rep${i}_simple.csv"
    
    awk 'BEGIN {print "ID_Sequence,Prediction_DVF"} NR>1 {
        pred = ($3 >= 0.5) ? "Virus" : "Autre";
        print $1 "," pred
    }' "$input" > "$output"
    
    echo "Réplicat $i de DVF terminé avec en-têtes."
done