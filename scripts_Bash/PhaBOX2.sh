#!/bin/bash

# Configuration des chemins
INPUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets"
OUTPUT_BASE="/srv/scratch/alamiex/jeux_de_données/output_cenote"
SIF="/srv/scratch/alamiex/virome-bench-v6.sif"
DB_PATH="/srv/scratch/alamiex/database/cenote_db"
PYHMMER_FIX="/srv/scratch/alamiex/mock_labo/pyhmmer_runner_fixed.py"

# Réglages parallélisme (4 jobs de 28 CPUs)
MAX_JOBS=4
CPUS_PER_JOB=28

mkdir -p "$OUTPUT_BASE"

echo "Début du traitement Cenote-Taker 3 pour les 10 réplicats..."

for i in {1..10}
do
    echo "------------------------------------------"
    echo "Traitement du réplicat $i en cours..."

    IN_FASTA="$INPUT_DIR/dataset_final_rep${i}_clean.fasta"
    OUT_REP="$OUTPUT_BASE/rep${i}"
    LOG_FILE="$OUT_REP/cenote_run_rep${i}.log"

    mkdir -p "$OUT_REP"

    # Exécution via Singularity (en arrière-plan)
    singularity exec -B /srv/scratch:/srv/scratch \
        -B "$PYHMMER_FIX":/opt/conda/envs/virome_shah/lib/python3.10/site-packages/cenote/python_modules/pyhmmer_runner.py \
        --pwd "$OUT_REP" \
        "$SIF" \
        cenotetaker3 -c "$IN_FASTA" -r "results" -p T --cenote-dbs "$DB_PATH" \
        --lin_minimum_hallmark_genes 1 --minimum_length_circular 300 --minimum_length_linear 300 \
        -t "$CPUS_PER_JOB" > "$LOG_FILE" 2>&1 &

    # Gestion du parallélisme : limite à MAX_JOBS en simultané
    if [[ $(jobs -r -p | wc -l) -ge $MAX_JOBS ]]; then
        wait -n
    fi
done

wait
echo "------------------------------------------"
echo "Traitement global terminé. Résultats dans : $OUTPUT_BASE"
