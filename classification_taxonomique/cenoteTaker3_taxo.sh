echo "--- REPRISE CENOTE (EXTRACTION INTELLIGENTE) ---"

for i in {1..10}
do
    INPUT="rep${i}/results/results_virus_summary.tsv"
    OUTPUT="rep${i}_CENOTE_DETAIL.tsv"

    if [ ! -f "$INPUT" ]; then continue; fi

    echo -e "Contig_ID\tFamille_Cible\tLignee_Complete" > "$OUTPUT"

    awk -F'\t' 'NR>1 {
        id = $2;
        full_lineage = "Unclassified";
        
        # On cherche la colonne qui contient la taxonomie virale
        for (f=1; f<=NF; f++) {
            if ($f ~ /Viruses/ && $f ~ /;/) {
                full_lineage = $f;
                break;
            }
        }
        
        # Extraction de la famille (f_) ou classe (c_)
        res = "Unclassified";
        n = split(full_lineage, a, ";");
        
        f_fam=""; f_class="";
        for (j=1; j<=n; j++) {
            if (a[j] ~ /^f_/) { f_fam = substr(a[j], 3); }
            if (a[j] ~ /^c_/) { f_class = substr(a[j], 3); }
        }
        
        if (f_fam != "") res = f_fam;
        else if (f_class != "") res = f_class;

        print id "\t" res "\t" full_lineage
    }' "$INPUT" >> "$OUTPUT"
    
    echo "✅ Réplicat $i : Terminé avec succès."
done