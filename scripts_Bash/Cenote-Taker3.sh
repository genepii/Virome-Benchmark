#!/bin/bash

# Configuration des chemins
INPUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets"
OUTPUT_BASE="/srv/scratch/alamiex/jeux_de_données/output_cenote"
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"
DB_PATH="/srv/scratch/alamiex/database/cenote_db"
PYHMMER_FIX="/srv/scratch/alamiex/mock_labo/pyhmmer_runner_fixed.py"

# Réglages parallélisme
MAX_JOBS=4 
CPUS_PER_JOB=28

mkdir -p "$OUTPUT_BASE"

echo "Début du traitement Cenote-Taker 3 (Mode Parallèle)..."

for i in {1..10}
do
    echo "------------------------------------------"
    echo "Lancement du réplicat $i..."
    
    IN_FASTA="$INPUT_DIR/dataset_final_rep${i}_clean.fasta"
    OUT_REP="$OUTPUT_BASE/rep${i}"
    LOG_FILE="$OUT_REP/run.log"
    
    mkdir -p "$OUT_REP"

    time singularity exec -B /srv/scratch:/srv/scratch \
        -B "$PYHMMER_FIX":/opt/conda/envs/virome_shah/lib/python3.10/site-packages/cenote/python_modules/pyhmmer_runner.py \
        --pwd "$OUT_REP" \
        "$SIF" \
        cenotetaker3 -c "$IN_FASTA" -r "results" -p T --cenote-dbs "$DB_PATH" \
        --lin_minimum_hallmark_genes 1 --minimum_length_circular 300 --minimum_length_linear 300 \
        -t "$CPUS_PER_JOB" > "$LOG_FILE" 2>&1 &

    # Limite le nombre de jobs simultanés
    if [[ $(jobs -r -p | wc -l) -ge $MAX_JOBS ]]; then
        wait -n
    fi
done

wait
echo "------------------------------------------"
echo "Traitement Cenote terminé pour tous les réplicats."
