# ==============================================================================
# SCRIPT TAXO & BINAIRE - ANALYSE DE LA PERFORMANCE
# ==============================================================================

library(tidyverse)

base_path <- "C:/Users/ALAMIEX/Desktop/Projet_Soufiane/Workflow_R/mock_metaG/"
fichiers_taxo <- c(
  "U80" = paste0(base_path, "Mock_metaG_U80_pred_and_taxo.csv"), 
  "U81" = paste0(base_path, "Mock_metaG_U81_pred_and_taxo.csv"), 
  "U82" = paste0(base_path, "Mock_metaG_U82_pred_and_taxo.csv")
)

charger_donnees_completes <- function(chemin) {
  if(!file.exists(chemin)) return(NULL)
  df <- read.csv(chemin, sep = ";", header = TRUE, stringsAsFactors = FALSE, check.names = FALSE)
  if(ncol(df) <= 1) df <- read.delim(chemin, stringsAsFactors = FALSE, check.names = FALSE)
  colnames(df) <- trimws(colnames(df))
  
  # 1. Identification des colonnes
  col_gt_taxo <- grep("Ground_Truth_taxo", colnames(df), value = TRUE)[1]
  col_gt_bin  <- grep("Ground_Truth_binaire", colnames(df), value = TRUE)[1]
  
  # 2. Pivot pour la taxonomie
  cols_taxo <- grep("taxonomy_", colnames(df), value = TRUE)
  df_taxo <- df %>%
    select(ID_sequence, !!sym(col_gt_taxo), all_of(cols_taxo)) %>%
    pivot_longer(cols = all_of(cols_taxo), names_to = "outil", values_to = "taxo_predite") %>%
    mutate(outil = str_remove(outil, "taxonomy_"))

  # 3. Pivot pour le binaire
  cols_bin <- grep("prediction_", colnames(df), value = TRUE)
  df_bin <- df %>%
    select(ID_sequence, !!sym(col_gt_bin), all_of(cols_bin)) %>%
    pivot_longer(cols = all_of(cols_bin), names_to = "outil", values_to = "bin_predit") %>%
    mutate(outil = str_remove(outil, "prediction_"))

  # 4. Fusion des deux
  df_final <- left_join(df_taxo, df_bin, by = c("ID_sequence", "outil")) %>%
    rename(GT_Taxo = !!sym(col_gt_taxo), GT_Bin = !!sym(col_gt_bin))
  
  return(df_final)
}

# Traitement des données
df_plot <- map_df(fichiers_taxo, charger_donnees_completes, .id = "Dataset") %>%
  mutate(taxo_predite = replace_na(as.character(taxo_predite), "Unknown")) %>%
  mutate(Assignation = case_when(
    # BACTÉRIES (MARRON) - Priorité
    (str_detect(tolower(taxo_predite), "aceae|ales|bacteria") & !str_detect(tolower(taxo_predite), "virales")) |
    str_detect(tolower(taxo_predite), "pseudo|rhizob|burkhold|bacill|staphyl|entero|lysob|chromob|nitrosom|steno|agrobact|escherich|salmonel") ~ "Bactérie/Euk. (Marron)",
    
    # PHAGES CIBLES
    str_detect(tolower(taxo_predite), "podovir|lederberg|autographi|peeveel|casjens") ~ "Podoviridae (P22)",
    str_detect(tolower(taxo_predite), "ounavir|anderson|felix|chase|aliceevans") ~ "Ounaviridae (F0)",
    str_detect(tolower(taxo_predite), "siphovir|lambdav|drexler|guern|hendrix|vequint|phieta|bievre|peduovir|vandenende|glaede|radost") ~ "Siphoviridae (ES18)",
    str_detect(tolower(taxo_predite), "inovir|inovirus|tubulavir") ~ "Inoviridae (M13)",
    str_detect(tolower(taxo_predite), "fiersvir|emesvir|ms2") ~ "Fiersviridae (F2)",
    
    # GÉNÉRIQUE / AUTRES
    str_detect(tolower(taxo_predite), "caudovir|herelle|strabo|kyano|mesyanzhinov|algavir|imitervir") ~ "Caudoviricetes / Autres Virus",
    taxo_predite %in% c("Unknown", "Unassigned_Family", "unclassified", "unmapped", "0", "") ~ "Unknown / Unclassified",
    TRUE ~ "Caudoviricetes / Autres Virus"
  ))

# Palette
palette_finale <- c(
  "Podoviridae (P22)"="#1F78B4", "Ounaviridae (F0)"="#33A02C", "Siphoviridae (ES18)"="#E31A1C",
  "Inoviridae (M13)"="#FF7F00", "Fiersviridae (F2)"="#6A3D9A", "Caudoviricetes / Autres Virus"="#FDBF6F",
  "Bactérie/Euk. (Marron)"="#B15928", "Unknown / Unclassified"="#A6A6A6"
)

# Graphique avec FACETTING par statut binaire
for (ds in unique(df_plot$Dataset)) {
  
  data_ds <- subset(df_plot, Dataset == ds)
  
  p <- ggplot(data_ds, aes(x = outil, fill = Assignation)) +
    geom_bar(position = "stack", color = "black", linewidth = 0.1) +
    # On sépare le graphique en deux : ce que l'outil a dit être un "virus" vs "autre"
    facet_grid(. ~ bin_predit, scales = "free_x", space = "free_x") +
    scale_fill_manual(values = palette_finale) + 
    theme_bw() +
    labs(title = paste("Benchmark Taxo & Binaire :", ds),
         subtitle = "Séparation par prédiction binaire (virus vs autre)",
         x = "Outils", y = "Nombre de séquences") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
          strip.background = element_rect(fill = "grey90"),
          strip.text = element_text(face = "bold"))

  print(p)
  ggsave(paste0(base_path, "Benchmark_Taxo_Binaire_", ds, ".png"), plot = p, width = 16, height = 9)
}
