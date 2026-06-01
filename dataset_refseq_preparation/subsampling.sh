#!/bin/bash

# Dossier de sortie
mkdir -p datasets_rep

for i in {1..10}
do
    echo "------------------------------------------"
    echo "...Génération du réplicat $i (Ratio 1:10:17)..."
    
    # 1. Extraction VIRUS (10 000)
    singularity exec -B /srv/scratch:/srv/scratch /srv/scratch/alamiex/benchvir/virome-bench-v4.sif seqkit sample -n 10000 -s $i --two-pass /srv/scratch/alamiex/benchvir/viral_genomes/virus_artif_ctgs.fasta -o /srv/scratch/alamiex/benchvir/datasets_rep/Virus_tmp.fasta
    
    # 2. Extraction BACTÉRIES (100 000)
    singularity exec -B /srv/scratch:/srv/scratch /srv/scratch/alamiex/benchvir/virome-bench-v4.sif seqkit sample -n 100000 -s $i --two-pass /srv/scratch/alamiex/benchvir/bacteria/bacteria_artifi_ctgs.fasta -o /srv/scratch/alamiex/benchvir/datasets_rep/bact_tmp.fasta
    
    # 3. Extraction HUMAIN (170 000)
    singularity exec -B /srv/scratch:/srv/scratch /srv/scratch/alamiex/benchvir/virome-bench-v4.sif seqkit sample -n 170000 -s $i --two-pass /srv/scratch/alamiex/benchvir/human_genome/Human_artif_ctgs.fasta -o /srv/scratch/alamiex/benchvir/datasets_rep/human_tmp.fasta
    
    # 4. Fusion et création du dataset final
    OUTPUT_FILE="datasets_rep/dataset_benchmark_rep${i}.fasta"
    cat Virus_tmp.fasta bact_tmp.fasta human_tmp.fasta > $OUTPUT_FILE
    
    # 5. Vérification rapide du nombre de séquences
    NB_SEQ=$(grep -c ">" $OUTPUT_FILE)
    echo "Réplicat $i terminé : $NB_SEQ séquences générées."
    
    # 6. Nettoyage des fichiers temporaires pour économiser l'espace
    rm Virus_tmp.fasta bact_tmp.fasta human_tmp.fasta
    
done

echo "------------------------------------------"
echo "Tous les réplicats sont prêts dans le dossier datasets_rep/"