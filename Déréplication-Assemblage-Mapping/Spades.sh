#!/bin/bash

# Chemins
# Assure-toi que ce dossier contient bien tes 12 fichiers _clean.fastq.gz
READS_DIR="/srv/scratch/alamiex/mock_marina/reads"
OUTPUT_BASE="/srv/scratch/alamiex/mock_marina/assembly_E"
SIF_FILE="/srv/scratch/alamiex/virome-bench-v8.sif"

# Création du dossier parent pour les assemblages
mkdir -p "$OUTPUT_BASE"

# Boucle sur tous les fichiers clean.fastq.gz
for fastq in "$READS_DIR"/*_clean.fastq.gz; do
    
    # Extraire le nom de l'échantillon (ex: MOCK-E1)
    filename=$(basename "$fastq")
    sample_name=${filename%_clean.fastq.gz}
    
    # Vérification : si le dossier d'assemblage existe déjà, on passe au suivant 
    # (utile si le script s'arrête et que tu dois le relancer)
    if [ -d "$OUTPUT_BASE/$sample_name" ]; then
        echo "⏭️  Saut de $sample_name : déjà assemblé."
        continue
    fi

    echo "-------------------------------------------------------"
    echo "🚀 DEBUT ASSEMBLAGE : $sample_name"
    echo "📅 $(date)"
    echo "-------------------------------------------------------"

    # Lancement de metaSPAdes via Singularity
    # Utilisation de -t 16 comme demandé
    singularity exec -B /srv/scratch:/srv/scratch "$SIF_FILE" \
    metaspades.py --12 "$fastq" \
    -o "$OUTPUT_BASE/$sample_name" \
    -t 16 \
    -m 128 \
    --phred-offset 33 \
    --only-assembler

    echo "✅ TERMINE : $sample_name à $(date)"
done