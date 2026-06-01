echo "--- EXTRACTION GENOMAD : FAMILLE + LIGNÉE ---"

for i in {1..10}
do
    # Attention au chemin : vérifie bien l emplacement du fichier summary.tsv
    INPUT="rep${i}/dataset_final_rep${i}_summary/dataset_final_rep${i}_virus_summary.tsv"
    OUTPUT="rep${i}_GENOMAD_DETAIL.tsv"

    if [ ! -f "$INPUT" ]; then 
        echo "⚠️ $INPUT introuvable"
        continue 
    fi

    echo -e "Contig_ID\tFamille_Cible\tLignee_Complete" > "$OUTPUT"

    # La taxonomie est en colonne 11
    awk -F'\t' 'NR>1 {
        id = $1;
        full_lineage = $11;
        res = "Unclassified";
        
        # On découpe par les points-virgules
        n = split(full_lineage, a, ";");
        
        # Stratégie : On cherche le rang qui finit par "viridae"
        found_fam = 0;
        for (j = n; j >= 1; j--) {
            if (a[j] ~ /viridae$/) {
                res = a[j];
                found_fam = 1;
                break;
            }
        }
        
        # Si pas de "viridae", on prend le dernier rang non vide (ex: Caudoviricetes)
        if (found_fam == 0) {
            for (j = n; j >= 1; j--) {
                if (a[j] != "") {
                    res = a[j];
                    break;
                }
            }
        }

        print id "\t" res "\t" full_lineage
    }' "$INPUT" >> "$OUTPUT"
    
    echo "✅ Réplicat $i terminé."
done