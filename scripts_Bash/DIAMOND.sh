#!/bin/bash

# Configuration des chemins
SIF="/srv/scratch/alamiex/tapoxy.sif"
INPUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets"
OUTPUT_DIR="/srv/scratch/alamiex/jeux_de_données/output_diamond_nr"
DB_PATH="/srv/scratch/alamiex/database/diamond_nr/nr_2026.dmnd"

mkdir -p "$OUTPUT_DIR"

echo "======================================================="
echo "--- TRAITEMENT DIAMOND : LES 10 RÉPLICATS ---"
echo "======================================================="

for i in {1..10}
do
    echo "-------------------------------------------------------"
    echo "[$(date +%T)] Traitement du réplicat $i / 10..."
    
    IN_FILE="$INPUT_DIR/dataset_final_rep${i}.fasta"
    OUT_FILE="$OUTPUT_DIR/rep${i}_contigs_LCA.txt"
    LOG_FILE="$OUTPUT_DIR/rep${i}_bench.log"

    # Sécurité : évite de recalculer ce qui est déjà fait
    if [[ -f "$OUT_FILE" ]]; then
        echo "✅ Le réplicat $i existe déjà (Passage au suivant)."
        continue
    fi

    if [[ -f "$IN_FILE" ]]; then
        echo "🚀 Lancement de Diamond Blastx (85 threads)..."
        
        # Exécution via Singularity
        (time nice -n 15 singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
        diamond blastx \
            --db "$DB_PATH" \
            --query "$IN_FILE" \
            --out "$OUT_FILE" \
            --threads 85 \
            --evalue 0.001 \
            -k 1 \
            --max-hsps 1 \
            --sensitive \
            --outfmt 102) 2> "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            echo "[$(date +%T)] ✨ Réplicat $i terminé avec succès."
        else
            echo "[$(date +%T)] ❌ Erreur sur le réplicat $i (voir $LOG_FILE)."
        fi
    else
        echo "⚠️ ERREUR : Fichier $IN_FILE introuvable."
    fi
done

echo "======================================================="
echo "--- TRAITEMENT TERMINÉ ---"
echo "======================================================="
