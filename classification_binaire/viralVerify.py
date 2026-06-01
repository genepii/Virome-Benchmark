#!/usr/bin/env python
# -*- coding: utf-8 -*-
import pandas as pd
import sys
import os

# Numéro du réplicat passé en argument par la boucle Bash
rep = sys.argv[1]

# 1. Chargement du référentiel (Tes 272 151 IDs)
kraken_file = "/srv/scratch/alamiex/jeux_de_données/concatenation/DVF_result/KRAKEN_lengths_rep%s.csv" % rep
df_master = pd.read_csv(kraken_file)

# On s'assure que la colonne d'ID est la clé de fusion
id_col = df_master.columns[0]
df_master = df_master[[id_col]].rename(columns={id_col: 'ID_Sequence'})

# 2. Chargement des prédictions ViralVerify
vv_file = "rep%s_viralverify_pred.csv" % rep
df_vv = pd.read_csv(vv_file)

# 3. Fusion pour garantir les 272 151 lignes
# Tout ID absent des résultats ViralVerify est mis à 'Autre'
final = pd.merge(df_master, df_vv, on='ID_Sequence', how='left')
final['Prediction_ViralVerify'] = final['Prediction_ViralVerify'].fillna('Autre')

# 4. Sortie du fichier final
output_name = "rep%s_FINAL_TABLE.csv" % rep
final.to_csv(output_name, index=False)