#!/bin/bash
export LC_ALL=C

# --- CONFIGURATION ---
# Dossier où se trouvent tes fichiers rep*_contigs_LCA.txt
DIAMOND_DIR="/srv/scratch/alamiex/jeux_de_données/output_diamond_nr"
# Ton fichier de référence taxonomique
TAX2LIN="ncbitax2lin_FIXED.tsv" 
# Dossier de sortie
FINAL_DIR="/srv/scratch/alamiex/jeux_de_données/extract_diamond_final"

mkdir -p "$FINAL_DIR"

echo "======================================================="
echo "--- 💎 EXTRACTION DIAMOND LCA : TOUS LES RÉPLICATS ---"
echo "======================================================="

# 1. Vérification du fichier de référence
if [ ! -f "$TAX2LIN" ]; then
    echo "❌ Erreur : $TAX2LIN introuvable dans $(pwd)"
    exit 1
fi

# 2. Boucle sur tous les fichiers rep*_contigs_LCA.txt
for LCA_FILE in ${DIAMOND_DIR}/rep*_contigs_LCA.txt
do
    [ -e "$LCA_FILE" ] || continue
    
    # Extraire le nom du réplicat (ex: rep1)
    REP_NAME=$(basename "$LCA_FILE" _contigs_LCA.txt)
    OUTPUT_CSV="${FINAL_DIR}/${REP_NAME}_prediction_diamond.csv"

    echo "[*] Analyse de $REP_NAME..."

    # 3. Jointure et détection VIRALE via AWK
    # On charge le fichier TAX2LIN en mémoire (Dictionnaire TaxID -> EstVirus)
    # Puis on traite le fichier LCA
    awk -F'\t' '
        BEGIN { 
            OFS=","
            # Charger les TaxIDs viraux depuis ncbitax2lin
            # On considère que la colonne 1 est le TaxID et qu on cherche "Viruses" dans la ligne
            while ((getline < "'"$TAX2LIN"'") > 0) {
                if ($0 ~ /[Vv]iruses/) {
                    is_virus[$1] = 1
                }
            }
            # Imprimer l entête du CSV
            print "ID_Sequence","prediction_diamond"
        }
        {
            # Dans le fichier LCA : $1 = ID_Sequence, $2 = TaxID
            # On vérifie si le TaxID ($2) est dans notre dictionnaire viral
            if (is_virus[$2] == 1) {
                print $1, "Virus"
            } else {
                print $1, "Autre"
            }
        }
    ' "$LCA_FILE" > "$OUTPUT_CSV"

    echo "    ✅ Terminé : $(wc -l < "$OUTPUT_CSV") lignes générées."
done

echo "======================================================="
echo "Extraction terminée ! Tes fichiers CSV sont ici : $FINAL_DIR"
ls -lh "$FINAL_DIR"/*.csv