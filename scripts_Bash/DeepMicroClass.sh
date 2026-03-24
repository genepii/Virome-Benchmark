#!/bin/bash

# Configuration des chemins
INPUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets"
OUTPUT_BASE="/srv/scratch/alamiex/jeux_de_données/output_dmc"
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"

# Le chemin du modèle est interne au container SIF
MODEL="/opt/conda/envs/virome_shah/lib/python3.10/site-packages/DeepMicroClass/model.ckpt"

mkdir -p "$OUTPUT_BASE"

echo "======================================================="
echo "--- DEEPMICROCLASS : TRAITEMENT DES 10 RÉPLICATS ---"
echo "======================================================="

for i in {1..10}
do
    echo "-------------------------------------------------------"
    echo "[$(date +%T)] Traitement du réplicat $i / 10..."
    
    IN_FILE="$INPUT_DIR/dataset_final_rep${i}.fasta"
    OUT_REP="$OUTPUT_BASE/rep${i}"
    
    # Vérification du fichier d'entrée
    if [[ ! -f "$IN_FILE" ]]; then
        echo "⚠️ ERREUR : Fichier $IN_FILE introuvable. Passage au suivant."
        continue
    fi

    mkdir -p "$OUT_REP"

    # Exécution de DeepMicroClass via Singularity
    # --mode hybrid : classification Virus vs Procaryote
    singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
    DeepMicroClass predict \
        -i "$IN_FILE" \
        -o "$OUT_REP" \
        --model "$MODEL" \
        --mode hybrid

    if [ $? -eq 0 ]; then
        echo "[$(date +%T)] ✅ Réplicat $i terminé."
    else
        echo "[$(date +%T)] ❌ Erreur lors du traitement du réplicat $i."
    fi
done

echo "======================================================="
echo "--- ANALYSE DEEPMICROCLASS TERMINÉE ---"
echo "======================================================="
