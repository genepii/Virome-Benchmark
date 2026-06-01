# ==============================================================================
# SCRIPT : MERGE GLOBAL ET MOYENNE DES PERFORMANCES (BENCHMARK GLOBAL)
# ==============================================================================

library(tidyverse)
library(scales)

# 1. Configuration du répertoire
setwd("C:/Users/ALAMIEX/Desktop/Projet_Soufiane/Workflow_R/mock_simulé")

# 2. Liste des fichiers
fichiers <- c("S2" = "S2_MASTER_CONCATENATION.tsv", 
              "S7" = "S7_MASTER_CONCATENATION.tsv", 
              "S9" = "S9_MASTER_CONCATENATION.tsv", 
              "S13" = "S13_MASTER_CONCATENATION.tsv")

# 3. Fonction de classification (Identique à la précédente pour rester cohérent)
classify_status <- function(pred, truth) {
  case_when(
    pred %in% c("not_detected", "Unclassified", "not_in_truth", "Unknown") | is.na(pred) ~ "Oubli (Non détecté)",
    pred == truth & !truth %in% c("Caudoviricetes incertae sedis", "Unknown Viral Family") ~ "Succès (Famille Identifiée)",
    truth == "Caudoviricetes incertae sedis" & (grepl("viridae", pred) | grepl("Caudoviricetes", pred)) ~ "Caudoviricetes (Classe seule)",
    truth == "Unknown Viral Family" & grepl("viridae", pred) ~ "Famille prédite sur Inconnu",
    TRUE ~ "Erreur d'assignation (Mismatch)"
  )
}

# 4. Chargement et Fusion de tous les échantillons
cat("Fusion des 4 datasets...\n")

data_merged <- map_df(names(fichiers), function(nom_ech) {
  df <- read_tsv(fichiers[nom_ech], show_col_types = FALSE) %>% mutate(Sample = nom_ech)
  
  # Barre Truth
  truth_bar <- df %>%
    distinct(Contig_ID, Ground_Truth, Sample) %>%
    mutate(Outil = "0_Truth",
           Statut = case_when(
             Ground_Truth == "Caudoviricetes incertae sedis" ~ "Caudoviricetes (Classe seule)",
             Ground_Truth == "Unknown Viral Family" ~ "Famille prédite sur Inconnu",
             TRUE ~ "Succès (Famille Identifiée)"
           )) %>%
    group_by(Outil, Statut) %>% summarise(Count = n(), .groups = 'drop')
  
  # Stats Outils
  tools_stats <- df %>%
    pivot_longer(cols = starts_with("Famille_"), names_to = "Outil", values_to = "Pred") %>%
    mutate(Outil = str_remove(Outil, "Famille_"),
           Statut = classify_status(Pred, Ground_Truth)) %>%
    group_by(Outil, Statut) %>% summarise(Count = n(), .groups = 'drop')
  
  bind_rows(truth_bar, tools_stats)
})

# 5. Calcul de la MOYENNE GLOBALE
# Ici on additionne les comptes de tous les échantillons pour chaque outil/statut
data_moyenne <- data_merged %>%
  group_by(Outil, Statut) %>%
  summarise(Total_Count = sum(Count), .groups = 'drop')

# 6. Mise en forme (Ordre et Couleurs)
data_moyenne$Statut <- factor(data_moyenne$Statut, levels = c(
  "Succès (Famille Identifiée)", 
  "Caudoviricetes (Classe seule)", 
  "Famille prédite sur Inconnu", 
  "Erreur d'assignation (Mismatch)",
  "Oubli (Non détecté)"
))

couleurs <- c(
  "Succès (Famille Identifiée)"     = "#2E7D32", 
  "Caudoviricetes (Classe seule)"   = "#2196F3", 
  "Famille prédite sur Inconnu"     = "#FFEB3B", 
  "Erreur d'assignation (Mismatch)" = "#FF9800", 
  "Oubli (Non détecté)"             = "#E53935"
)

# 7. Création du Graphique Moyen
p_global <- ggplot(data_moyenne, aes(x = Outil, y = Total_Count, fill = Statut)) +
  geom_bar(stat = "identity", position = "fill", width = 0.7) +
  # On affiche le nombre total cumulé sur les 4 échantillons
  geom_text(aes(label = Total_Count), position = position_fill(vjust = 0.5), size = 3.5, fontface = "bold") +
  geom_vline(xintercept = 1.5, linetype = "dashed", color = "black", linewidth = 1) +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = couleurs) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 12),
        legend.position = "bottom") +
  labs(title = "Benchmark Global (Moyenne des 4 échantillons)",
       subtitle = "Performance cumulée : S2, S7, S9, S13",
       x = "Vérité Terrain | Outils", y = "Proportion Moyenne (%)", fill = "Statut :")

# Affichage et Sauvegarde
print(p_global)
ggsave("Benchmark_GLOBAL_Moyenne.pdf", plot = p_global, width = 10, height = 8)
