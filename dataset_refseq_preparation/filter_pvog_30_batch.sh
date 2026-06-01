#!/bin/bash

# --- CONFIGURATION CORRIGÉE ---
SIF="/srv/scratch/alamiex/virome-bench-v4.sif"

# Vérification immédiate de l'existence de l'image
if [ ! -f "$SIF" ]; then
    echo "ERREUR : L'image Singularity est introuvable au chemin : $SIF"
    exit 1
fi

# Définition des commandes
PRODIGAL="singularity exec -B /srv/scratch:/srv/scratch $SIF prodigal"
HMMSEARCH="singularity exec -B /srv/scratch:/srv/scratch $SIF hmmsearch"
SEQKIT="singularity exec -B /srv/scratch:/srv/scratch $SIF seqkit"

INPUT_FASTA=$1
OUTPUT_FASTA=$2
DB_PVOG=$3

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <input.fasta> <output.fasta> <path_to_pvogs.hmm>"
    exit 1
fi

mkdir -p "./tmp_work"
PREFIX=$(basename "${INPUT_FASTA%.*}")

echo "--- DEBUT DU TRAITEMENT GLOBAL ---"

# 1. Prodigal
echo "[1/4] Prédiction des gènes avec Prodigal..."
$PRODIGAL -i "$INPUT_FASTA" -a "./tmp_work/${PREFIX}_prot.faa" -p meta -q

# 2. HMMER
echo "[2/4] Recherche des signatures virales (pVOG) avec HMMER..."
$HMMSEARCH --cpu 32 -E 1e-5 --tblout "./tmp_work/${PREFIX}.tblout" "$DB_PVOG" "./tmp_work/${PREFIX}_prot.faa" > /dev/null

# 3. Analyse des ratios
echo "[3/4] Analyse des ratios et création de la liste d'exclusion..."

# Extraction des IDs originaux (on retire l'index du gène ajouté par Prodigal)
grep ">" "./tmp_work/${PREFIX}_prot.faa" | sed 's/>//' | rev | cut -d'_' -f2- | rev | sort | uniq -c > "./tmp_work/counts_total.txt"

grep -v "^#" "./tmp_work/${PREFIX}.tblout" | awk '{print $1}' | rev | cut -d'_' -f2- | rev | sort | uniq -c > "./tmp_work/counts_hits.txt"

# Calcul du ratio 30%
awk 'NR==FNR { total[$2]=$1; next } { hits=$1; id=$2; if (id in total) { if (hits/total[id] >= 0.30) { print id } } }' \
"./tmp_work/counts_total.txt" "./tmp_work/counts_hits.txt" > "./tmp_work/blacklist.txt"

NUM_REMOVED=$(wc -l < "./tmp_work/blacklist.txt")
echo "   -> $NUM_REMOVED contigs identifiés comme viraux (ratio >= 30%) seront supprimés."

# 4. Filtrage final
echo "[4/4] Filtrage du fichier FASTA final avec SeqKit..."
$SEQKIT grep -v -f "./tmp_work/blacklist.txt" "$INPUT_FASTA" -o "$OUTPUT_FASTA"

# Nettoyage
rm -rf "./tmp_work"
echo "--- TERMINE : Fichier propre disponible ici : $OUTPUT_FASTA ---"