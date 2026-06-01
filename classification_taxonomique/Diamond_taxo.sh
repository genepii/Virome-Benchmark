#!/bin/bash
export LC_ALL=C

TAX2LIN_FIXED="ncbitax2lin_FIXED.tsv"


echo "--- ETAPE 2 : TRADUCTION ---"
for i in {1..10}
do
    INPUT="rep${i}_contigs_LCA.txt"
    OUTPUT="rep${i}_DIAMOND_DETAIL.tsv"
    
    if [ ! -f "$INPUT" ]; then
        echo "⚠️ Fichier $INPUT introuvable, skip."
        continue
    fi

    echo "Traitement Replicat $i..."
    
    # Préparation Diamond : TaxID (col 2) en première colonne pour la jointure
    awk -F'\t' '{print $2 "\t" $1}' "$INPUT" | sort -t$'\t' -k1,1 > tmp_diamond.txt

    # Jointure avec le dictionnaire
    join -t$'\t' -1 1 -2 1 tmp_diamond.txt "$TAX2LIN_FIXED" > tmp_joined.txt

    # Écriture de l'entête
    echo -e "Contig_ID\tFamille_Cible\tLignee_Complete" > "$OUTPUT"
    
    # Extraction : 
    # $2=ContigID, $3=Phylum, $4=Class, $5=Order, $6=Family, $7=Genus (selon ton dictionnaire)
    # On suit ta règle de fallback pour la Famille Cible
    awk -F'\t' '{
        id=$2; fam=$7; 
        if(fam=="") fam=$6; # fallback sur Order
        if(fam=="") fam=$5; # fallback sur Class
        if(fam=="") fam="Unclassified";
        
        # On affiche la lignée simplifiée demandée
        print id "\t" fam "\t" $3";"$4";"$5";"$6";"$7
    }' tmp_joined.txt >> "$OUTPUT"
    
    rm tmp_diamond.txt tmp_joined.txt
done

echo "Termine !"