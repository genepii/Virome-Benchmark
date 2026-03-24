#!/bin/bash

INPUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets"
OUTPUT_BASE="/srv/scratch/alamiex/jeux_de_données/output_genomad"
DB_PATH="/srv/scratch/alamiex/database/genomad_db"
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"

mkdir -p "$OUTPUT_BASE"

for i in {1..10}
do
    echo "Traitement du réplicat $i en cours..."
    
    IN_FILE="$INPUT_DIR/dataset_final_rep${i}.fasta"
    OUT_REP="$OUTPUT_BASE/rep${i}"
    
    mkdir -p "$OUT_REP"

    singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
    genomad end-to-end --cleanup "$IN_FILE" "$OUT_REP" "$DB_PATH"

    echo "Réplicat $i terminé avec succès."
done
