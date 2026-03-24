#!/bin/bash

# Configuration des chemins
INPUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets"
OUTPUT_BASE="/srv/scratch/alamiex/jeux_de_données/output_kraken2_C"
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"
KRAKEN_DB="/srv/scratch/alamiex/database/kraken_db"

mkdir -p "$OUTPUT_BASE"

echo "======================================================="
echo "--- KRAKEN2 : TRAITEMENT DES 10 RÉPLICATS ---"
echo "======================================================="

for i in {1..10}
do
    echo "-------------------------------------------------------"
    
    IN_FILE="$INPUT_DIR/dataset_final_rep${i}.fasta"
    REPORT_FILE="$OUTPUT_BASE/rep${i}_report.txt"
    OUT_FILE="$OUTPUT_BASE/rep${i}_kraken.out"

    # Sécurité : Évite de recalculer ce qui est déjà fait (Mode Reprise)
    if [[ -f "$REPORT_FILE" ]]; then
        echo "[SKIP] Réplicat $i : Déjà généré ($REPORT_FILE)."
        continue
    fi

    # Vérification du fichier d'entrée
    if [[ -f "$IN_FILE" ]]; then
        echo "[$(date +%T)] Lancement Kraken2 pour le réplicat $i (72 threads)..."
        
        time singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
            kraken2 --db "$KRAKEN_DB" \
            --threads 72 \
            --memory-mapping \
            --confidence 0.1 \
            --minimum-hit-groups 2 \
            --report "$REPORT_FILE" \
            --output "$OUT_FILE" \
            "$IN_FILE"
        
        if [ $? -eq 0 ]; then
            echo "[$(date +%T)] ✅ Réplicat $i terminé. Rapport : $REPORT_FILE"
        else
            echo "[$(date +%T)] ❌ Erreur lors de l'exécution du réplicat $i."
        fi
    else
        echo "⚠️ ERREUR : Fichier source $IN_FILE introuvable."
    fi
done

echo "======================================================="
echo "--- ANALYSE KRAKEN2 TERMINÉE ---"
echo "======================================================="
