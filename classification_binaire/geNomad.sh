for i in {1..10}
do
    # Construction du chemin dynamique
    input="rep${i}/dataset_final_rep${i}_aggregated_classification/dataset_final_rep${i}_aggregated_classification.tsv"
    output="geNomad_results_rep${i}_simple.csv"
    
    echo "Traitement de geNomad réplicat $i..."
    
    awk -F'\t' 'BEGIN {OFS=","; print "ID_Sequence,Prediction_geNomad"} 
    NR>1 {
        pred = ($4 >= 0.5) ? "Virus" : "Autre";
        print $1, pred
    }' "$input" > "$output"
done