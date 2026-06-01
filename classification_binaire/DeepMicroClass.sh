for i in {1..10}
do
    input="DMC_results/rep${i}_DMC_final.csv"
    output="DMC_results/rep${i}_DMC_simple.csv"
    
    echo "Traitement du réplicat $i..."
    
    awk -F',' 'BEGIN {OFS=","} 
    NR==1 {
        # On ne garde que les deux premières en-têtes modifiées
        print "ID_Sequence", "Prediction_DMC" 
    } 
    NR>1 {
        # Transformation du score en texte
        type = ($2 >= 0.5) ? "Virus" : "Autre";
        # On imprime seulement l ID et la prédiction
        print $1, type
    }' "$input" > "$output"
done

echo "Terminé. Tes 10 fichiers simplifiés sont dans le dossier DMC_results/."