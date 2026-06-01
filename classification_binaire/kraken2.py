#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import os

# Récupération du numéro du réplicat
if len(sys.argv) < 2:
    print("Erreur : Il faut fournir le numéro du réplicat en argument.")
    sys.exit(1)

rep = sys.argv[1]
report_file = "rep%s_report.txt" % rep
out_file = "rep%s_kraken.out" % rep
final_file = "rep%s_FINAL_TABLE_KRAKEN.csv" % rep

# 1. On liste tous les TaxIDs qui sont des virus (branche 10239 et ses enfants)
virus_ids = set()
in_virus_branch = False
min_indent = 0

if not os.path.exists(report_file):
    print("Erreur : %s introuvable" % report_file)
    sys.exit(1)

with open(report_file, 'r') as f:
    for line in f:
        parts = line.split('\t')
        if len(parts) < 6: continue
        
        taxid = parts[4].strip()
        name_col = parts[5]
        indent = len(name_col) - len(name_col.lstrip())
        
        # On repère le début de la branche Virus
        if taxid == "10239":
            in_virus_branch = True
            min_indent = indent
            virus_ids.add(taxid)
        elif in_virus_branch:
            # Si on sort de l'indentation de la branche, on s'arrête
            if indent <= min_indent:
                in_virus_branch = False
            else:
                virus_ids.add(taxid)

# 2. On crée le fichier final avec distinction Virus, Unclassified et Autre
with open(final_file, 'w') as out:
    out.write("ID_Sequence,Prediction_Kraken\n")
    
    if not os.path.exists(out_file):
        print("Erreur : %s introuvable" % out_file)
        sys.exit(1)

    with open(out_file, 'r') as f:
        for line in f:
            parts = line.split('\t')
            if len(parts) >= 3:
                seq_id = parts[1]
                tax_id = parts[2].strip() # Nettoyage pour la comparaison
                
                # Logique de marquage
                if tax_id == "0":
                    pred = "Unclassified"
                elif tax_id in virus_ids:
                    pred = "Virus"
                else:
                    pred = "Autre"
                
                out.write("%s,%s\n" % (seq_id, pred))

print("Réplicat %s : Fichier %s généré avec distinction Unclassified." % (rep, final_file))