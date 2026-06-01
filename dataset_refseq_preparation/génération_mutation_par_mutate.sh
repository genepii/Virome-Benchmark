#!/bin/bash

# --- CONFIGURATION ---
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"
# Utilisation de wildcards pour éviter les pièges d'accents sur "données"
BASE_DIR="/srv/scratch/alamiex/jeux_de_donn*/datasets_complets"
OUT_DIR="/srv/scratch/alamiex/jeux_de_donn*/datasets_complets/mutated_steps"

echo "--- DÉMARRAGE DU SCRIPT ---"

# 1. On résout le chemin réel (pour enlever les étoiles)
REAL_INPUT_DIR=$(ls -d $BASE_DIR 2>/dev/null)
REAL_OUT_DIR="/srv/scratch/alamiex/jeux_de_données/datasets_complets/mutated_steps"

if [ -z "$REAL_INPUT_DIR" ]; then
    echo "❌ ERREUR : Impossible de trouver le dossier source (vérifiez le chemin /srv/scratch/alamiex/...)"
    exit 1
fi

mkdir -p "$REAL_OUT_DIR"

# 2. Boucle sur les 10 réplicats
for i in {1..10}
do
    INPUT="$REAL_INPUT_DIR/dataset_final_rep${i}.fasta"
    
    if [ ! -f "$INPUT" ]; then
        echo "⚠️  Réplicat $i absent ($INPUT), on passe au suivant."
        continue
    fi

    # Dossier spécifique par réplicat
    SUB_OUT="$REAL_OUT_DIR/rep${i}"
    mkdir -p "$SUB_OUT"

    echo "📂 Traitement Réplicat $i -> $SUB_OUT"

    # 3. Boucle de mutation
    for VAL in 95 90 85 80 75 70 65 60 55 50
    do
        ID="0.$VAL"
        OUT_FILE="$SUB_OUT/rep${i}_id_${VAL}.fasta"

        # On lance la mutation SANS cacher les erreurs cette fois
        singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
        mutate.sh in="$INPUT" out="$OUT_FILE" id="$ID" -da

        # Vérification immédiate
        if [ -f "$OUT_FILE" ] && [ -s "$OUT_FILE" ]; then
            echo "   ✅ ID $VAL% : Créé ($(du -sh "$OUT_FILE" | cut -f1))"
        else
            echo "   ❌ ID $VAL% : ÉCHEC (Le fichier n'a pas été généré)"
        fi
    done
done

echo "--- FIN DU SCRIPT ---"