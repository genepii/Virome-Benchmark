#!/bin/bash

# Chemins
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"
# On pointe vers ton nouveau dossier d'assemblage eMAG
BASE_DIR="/srv/scratch/alamiex/mock_marina/assembly_E"

# Paramètres CD-HIT
# -c 0.95 (95% identité), -aS 0.8 (80% couverture), -M 0 (mémoire illimitée), -T 16 (on passe à 16 threads)
OPTS="-c 0.95 -n 10 -aS 0.8 -d 0 -M 0 -T 24"

echo "--- 🧬 DÉMARRAGE DÉRÉPLICATION INDIVIDUELLE (CD-HIT) ---"

# On boucle sur tous les fichiers .fasta du dossier
for fasta in "${BASE_DIR}"/*.fasta; do
    # On récupère juste le nom du fichier sans l'extension
    FILENAME=$(basename "$fasta" .fasta)
    
    # On saute les fichiers qui sont déjà des résultats de CD-HIT (_rep.fasta)
    if [[ "$FILENAME" == *"_rep"* ]]; then
        continue
    fi

    echo "[*] Traitement de : ${FILENAME}.fasta"
    
    singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
    cd-hit-est -i "${BASE_DIR}/${FILENAME}.fasta" \
               -o "${BASE_DIR}/${FILENAME}_rep.fasta" \
               $OPTS
               
    echo "✅ Terminé pour $FILENAME"
    echo "------------------------------------------------"
done

echo "✨ Toutes les déréplications sont terminées."