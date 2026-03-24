#!/bin/bash

# Configuration des chemins
INPUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets"
OUTPUT_BASE="/srv/scratch/alamiex/jeux_de_données/output_viralm"
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"
MODEL_DB="/srv/scratch/alamiex/database/model_viraLM"

mkdir -p "$OUTPUT_BASE"

echo "======================================================="
echo "--------- VIRALM : TRAITEMENT DES 10 RÉPLICATS --------"
echo "======================================================="

for i in {1..10}
do
    echo "-------------------------------------------------------"
    echo "[$(date +%T)] Traitement du réplicat $i / 10..."
    
    IN_FILE="$INPUT_DIR/dataset_final_rep${i}.fasta"
    OUT_DIR="$OUTPUT_BASE/rep${i}"
    
    # Vérification du fichier d'entrée
    if [[ ! -f "$IN_FILE" ]]; then
        echo "⚠️ ERREUR : Fichier $IN_FILE introuvable. Passage au suivant."
        continue
    fi

    mkdir -p "$OUT_DIR"

    # Limitation stricte des threads (OMP/MKL) et du batch_size pour la stabilité CPU
    singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
    env OMP_NUM_THREADS=16 MKL_NUM_THREADS=16 \
    viralm --input "$IN_FILE" \
        --output "$OUT_DIR" \
        --database "$MODEL_DB" \
        --len 300 \
        --threads 16 \
        --batch_size 8 \
        --filename "viraLM_rep${i}" \
        --force

    if [ $? -eq 0 ]; then
        echo "[$(date +%T)] ✅ Réplicat $i terminé."
    else
        echo "[$(date +%T)] ❌ Erreur lors du traitement du réplicat $i."
    fi
done

echo "======================================================="
echo "--- ANALYSE VIRALM TERMINÉE ---"
echo "======================================================="
