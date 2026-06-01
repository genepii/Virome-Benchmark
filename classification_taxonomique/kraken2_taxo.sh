#!/bin/bash
export LC_ALL=C

# Chemins
TAX2LIN="/srv/scratch/alamiex/jeux_de_données/jeux_muté/output_kraken2_mutated/ncbitax2lin_FIXED.tsv"
ROOT_DIR="/srv/scratch/alamiex/jeux_de_données/jeux_muté/output_kraken2_mutated"

cd "$ROOT_DIR" || exit

GLOBAL_OUTPUT="KRAKEN2_ALL_RESULTS.tsv"

echo "--- 🧬 EXTRACTION KRAKEN2 (FORMAT HARMONISÉ) ---"

# Entête identique à geNomad/Cenote
echo -e "Replicat\tIdentite\tContig_ID\tFamille_Cible\tLignee_Complete" > "$GLOBAL_OUTPUT"

for i in {1..10}
do
    REP_DIR="rep${i}"
    if [ ! -d "$REP_DIR" ]; then continue; fi

    for INPUT in "$REP_DIR"/*_kraken.out
    do
        [ -f "$INPUT" ] || continue

        # Extraction de l'identité (ex: 100, 95...)
        ID_VAL=$(basename "$INPUT" | sed -E "s/.*_id_([0-9]+)_.*/\1/")

        # 1. Extraction TaxID ($3) et ContigID ($2)
        awk -F'\t' '$1=="C" {print $3 "\t" $2}' "$INPUT" | sort -t$'\t' -k1,1 > tmp_kraken.txt

        # 2. Jointure avec le dictionnaire
        join -t$'\t' -1 1 -2 1 tmp_kraken.txt "$TAX2LIN" > tmp_joined.txt

        # 3. Formatage identique à geNomad
        awk -F'\t' -v r="rep${i}" -v id_val="$ID_VAL" '{
            id = $2;
            phylum=$3; class=$4; order=$5; family=$6; genus=$7;

            # Reconstruction de la lignée complète (format semi-colon)
            full_lineage = phylum";"class";"order";"family";"genus;
            
            # Détermination de la Famille_Cible
            res = "Unclassified";
            if (family != "" && family != "NA") {
                res = family;
            } else if (order != "" && order != "NA") {
                res = order;
            } else if (class != "" && class != "NA") {
                res = class;
            }

            # Filtre viral pour ne pas polluer les résultats
            if (full_lineage ~ /[Vv]irus/ || full_lineage ~ /[Vv]iricetes/ || full_lineage ~ /[Vv]iridae/) {
                print r "\t" id_val "\t" id "\t" res "\t" full_lineage
            }
        }' tmp_joined.txt >> "$GLOBAL_OUTPUT"

        rm tmp_kraken.txt tmp_joined.txt
    done
    echo "✅ Réplicat $i : Terminé."
done

echo "--- ✅ FIN : Fichier $GLOBAL_OUTPUT prêt pour la comparaison ---"