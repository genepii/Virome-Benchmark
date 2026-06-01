#!/bin/bash

# Configuration des chemins
INPUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets"
OUTPUT_BASE="/srv/scratch/alamiex/jeux_de_données/output_virsorter2"
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"

mkdir -p "$OUTPUT_BASE"

echo "======================================================="
echo "--- VIRSORTER2 : TRAITEMENT DES 10 RÉPLICATS ---"
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

    time singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
        virsorter run -w "$OUT_DIR" \
        -i "$IN_FILE" \
        --provirus-off \
        -j 32 \
        all

    if [ $? -eq 0 ]; then
        echo "[$(date +%T)] ✅ Réplicat $i terminé."
    else
        echo "[$(date +%T)] ❌ Erreur lors du traitement du réplicat $i."
    fi
done

echo "======================================================="
echo "--- ANALYSE VIRSORTER2 TERMINÉE ---"
echo "======================================================="
