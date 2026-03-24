#!/bin/bash

# Configuration des chemins
INPUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets"
OUTPUT_BASE="/srv/scratch/alamiex/jeux_de_données/output_dvf"
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"

mkdir -p "$OUTPUT_BASE"

echo "======================================================="
echo "--- DEEPVIRFINDER : TRAITEMENT DES 10 RÉPLICATS ---"
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

    # Exécution de DeepVirFinder via Singularity
    # -l 300 : longueur minimale des contigs
    # -c 8   : nombre de CPUs alloués
    singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
        dvf -i "$IN_FILE" -o "$OUT_REP" -l 300 -c 8

    if [ $? -eq 0 ]; then
        echo "[$(date +%T)] ✅ Réplicat $i terminé."
    else
        echo "[$(date +%T)] ❌ Erreur sur le réplicat $i."
    fi
done

echo "======================================================="
echo "--- ANALYSE DEEPVIRFINDER TERMINÉE ---"
echo "======================================================="
