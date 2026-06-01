#!/bin/bash

# ========================================================================
# 📜 SCRIPT DE MAPPING TRIPLE COUCHE (HUMAIN, CIBLES, VIROME GLOBAL)
# ========================================================================
# Objectif : Générer une vérité de terrain robuste pour les mocks et les
#            échantillons cliniques (détection des phages et co-infections).

# --- CONFIGURATION DES CHEMINS ---
REF_DIR="/srv/scratch/alamiex/mock_marina/genomes_references"
NEW_REF_DIR="/srv/scratch/alamiex/mock_marina/new_mapping"
INPUT_DIR="/srv/scratch/alamiex/mock_marina/assembly_E"
OUT_DIR="/srv/scratch/alamiex/mock_marina/new_mapping/ground_truth_paf"
SIF="/srv/scratch/alamiex/virome-bench-v8.sif"

# Création du dossier de sortie s'il n'existe pas
mkdir -p "$OUT_DIR"

# --- FICHIERS DE RÉFÉRENCE ---
HUMAN_REF="$REF_DIR/human_Ref_genome.fna"
MOCK_REF="$REF_DIR/virus_mock_refs.fasta"
GLOBAL_VIRAL_REF="$NEW_REF_DIR/viral.1.1.genomic.fna"

echo "========================================================"
echo "🚀 DEBUT DU MAPPING GLOBAL ET DETECTION DES PHAGES"
echo "========================================================"
echo "📂 Entrée : $INPUT_DIR"
echo "📂 Sortie : $OUT_DIR"
echo "========================================================"

# --- BOUCLE DE TRAITEMENT DES FASTA ---
for fasta in "$INPUT_DIR"/*_final.fasta; do
    # Sécurité : si aucun fichier ne correspond, on arrête la boucle
    [ -f "$fasta" ] || continue
    
    # Extraction de l'identifiant de l'échantillon (ex: HSV_E1, VRS_E2, etc.)
    ID=$(basename "$fasta" _final.fasta)
    echo "[$(date +%T)] 🧬 Traitement de l'échantillon : $ID"

    # ------------------------------------------------------------------
    # 🛑 ÉTAPE 1 : Mapping contre l'HUMAIN (Identification du bruit de fond)
    # ------------------------------------------------------------------
    echo "   [+] 1/3 Alignement contre le génome Humain..."
    singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
    minimap2 -x asm5 -t 32 "$HUMAN_REF" "$fasta" > "$OUT_DIR/${ID}_human.paf"

    # ------------------------------------------------------------------
    # 🎯 ÉTAPE 2 : Mapping contre les VIRUS CIBLES (HSV, VRS ou Mock complet)
    # ------------------------------------------------------------------
    echo "   [+] 2/3 Alignement contre les virus cibles spécifiques..."
    if [[ $ID == HSV* ]]; then
        # On crée le fichier temporaire directement dans OUT_DIR pour Singularity
        cat "$REF_DIR/herpesvirus.fna" "$REF_DIR/MS2.fna" > "$OUT_DIR/tmp_hsv.fna"
        
        singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
        minimap2 -x asm5 -t 32 "$OUT_DIR/tmp_hsv.fna" "$fasta" > "$OUT_DIR/${ID}_targets.paf"
        
        rm "$OUT_DIR/tmp_hsv.fna"
        
    elif [[ $ID == VRS* ]]; then
        # On crée le fichier temporaire directement dans OUT_DIR pour Singularity
        cat "$REF_DIR/H_respiratory_syncytial.fna" "$REF_DIR/MS2.fna" > "$OUT_DIR/tmp_vrs.fna"
        
        singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
        minimap2 -x asm5 -t 32 "$OUT_DIR/tmp_vrs.fna" "$fasta" > "$OUT_DIR/${ID}_targets.paf"
        
        rm "$OUT_DIR/tmp_vrs.fna"
        
    else
        # Logique par défaut pour les échantillons de type MOCK
        singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
        minimap2 -x asm5 -t 32 "$MOCK_REF" "$fasta" > "$OUT_DIR/${ID}_targets.paf"
    fi

    # ------------------------------------------------------------------
    # 🌍 ÉTAPE 3 : Mapping contre REFSEQ VIRAL GLOBAL (Sauvetage des phages)
    # ------------------------------------------------------------------
    echo "   [+] 3/3 Alignement contre RefSeq Viral Global..."
    singularity exec -B /srv/scratch:/srv/scratch "$SIF" \
    minimap2 -x asm5 -t 32 "$GLOBAL_VIRAL_REF" "$fasta" > "$OUT_DIR/${ID}_global_viral.paf"

    echo "   [✓] Échantillon $ID traité avec succès."
    echo "--------------------------------------------------------"
done

echo "========================================================"
echo "✅ ANALYSE TERMINÉE OMNIPRÉSENTE"
echo "📂 Les 3 fichiers .paf par échantillon sont disponibles dans :"
echo "   $OUT_DIR"
echo "========================================================"