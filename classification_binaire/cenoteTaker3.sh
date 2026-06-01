#!/bin/bash

OUTPUT_BASE="/srv/scratch/alamiex/jeux_de_données/output_cenote"
KRAKEN_BASE="/srv/scratch/alamiex/jeux_de_données/concatenation/DVF_result"
FINAL_DIR="/srv/scratch/alamiex/jeux_de_données/output_cenote/extract"

mkdir -p "$FINAL_DIR"

echo "--- EXTRACTION CENOTE (CORRESPONDANCE EXACTE) ---"

for i in {1..10}
do
    KRAKEN_FILE="${KRAKEN_BASE}/KRAKEN_lengths_rep${i}.csv"
    CENOTE_FILE="${OUTPUT_BASE}/rep${i}/results/results_virus_summary.tsv"
    OUT_FILE="${FINAL_DIR}/cenote_final_rep${i}.csv"

    if [[ ! -f "$KRAKEN_FILE" || ! -f "$CENOTE_FILE" ]]; then
        echo "Réplicat $i : Fichiers manquants."
        continue
    fi

    # 1. On prend la colonne 2 telle quelle (ID complet)
    temp_ids=$(mktemp)
    awk -F'\t' 'NR>1 { print $2 }' "$CENOTE_FILE" | sort -u > "$temp_ids"

    # 2. Jointure avec Kraken (Comparaison exacte de la colonne 1)
    awk -F',' -v virus_list="$temp_ids" '
        BEGIN {
            while ((getline < virus_list) > 0) {
                virus_dict[$1] = 1
            }
            close(virus_list)
            print "ID_sequence,prediction_cenotetaker3"
        }
        NR>1 {
            id = $1
            if (id in virus_dict) {
                print id ",virus"
            } else {
                print id ",autre"
            }
        }
    ' "$KRAKEN_FILE" > "$OUT_FILE"

    rm "$temp_ids"
    
    nb_virus=$(grep -c ",virus" "$OUT_FILE")
    echo "Réplicat $i : Terminé ($nb_virus virus trouvés)."
done