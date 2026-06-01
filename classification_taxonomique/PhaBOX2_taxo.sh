echo "--- EXTRACTION PHABOX2 : FAMILLE + LIGNÉE COMPLÈTE ---"

for i in {1..10}
do
    INPUT="rep${i}/final_prediction/phagcn_prediction.tsv"
    OUTPUT="rep${i}_PHABOX_DETAIL.tsv"

    if [ ! -f "$INPUT" ]; then continue; fi

    # Création de l entête
    echo -e "Contig_ID\tFamille_Cible\tLignee_Complete" > "$OUTPUT"

    awk -F'\t' 'NR>1 {
        id = $1;
        full_lineage = $3;
        
        # 1. Extraction de la Famille (ou rang proche)
        res = "Unclassified";
        n = split(full_lineage, a, ";");
        
        f_fam=""; f_subfam=""; f_class="";
        for (j=1; j<=n; j++) {
            if (a[j] ~ /^family:/) { split(a[j], b, ":"); f_fam = b[2]; }
            if (a[j] ~ /^subfamily:/) { split(a[j], b, ":"); f_subfam = b[2]; }
            if (a[j] ~ /^class:/) { split(a[j], b, ":"); f_class = b[2]; }
        }
        
        if (f_fam != "") res = f_fam;
        else if (f_subfam != "") res = f_subfam;
        else if (f_class != "") res = f_class;

        # 2. On affiche l ID, la famille choisie et le lineage entier
        print id "\t" res "\t" full_lineage
    }' "$INPUT" >> "$OUTPUT"
    
    echo "✅ Réplicat $i : Terminé -> $OUTPUT"
done

echo "--- TOUS LES RÉPLICATS SONT PRÊTS ---"