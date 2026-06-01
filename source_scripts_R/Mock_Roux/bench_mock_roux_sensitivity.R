
# ==============================================================================
# PERFORMANCE CUMULÉE (S2, S7, S9, S13) : SENSIBILITÉ VS OUBLIS
# GÉNÉRATION D'UN SEUL GRAPHIQUE GLOBAL (PDF VECTORIEL)
# ==============================================================================

library(dplyr)
library(tidyr)
library(ggplot2)
library(scales)
library(purrr)

# 1. Configuration du répertoire
setwd("C:/Users/ALAMIEX/Desktop/Projet_Soufiane/Workflow_R/mock_simulé")

# 2. Liste des fichiers
fichiers <- c("S2" = "S2_DG_MASTER_MATRIX.csv", 
              "S7" = "S7_DG_MASTER_MATRIX.csv", 
              "S9" = "S9_DG_MASTER_MATRIX.csv", 
              "S13" = "S13_DG_MASTER_MATRIX.csv")

# 3. Chargement et fusion de tous les échantillons
cat("Fusion des données en cours...\n")

data_cumulee <- map_df(names(fichiers), function(nom_sample) {
  nom_fichier <- fichiers[nom_sample]
  
  if (!file.exists(nom_fichier)) {
    message(paste("⚠️ Fichier introuvable :", nom_fichier))
    return(NULL)
  }
  
  df <- read.csv(nom_fichier, sep = ",", stringsAsFactors = FALSE)
  outils_presents <- setdiff(colnames(df), c("ID_Sequence", "Length", "Truth"))
  
  # Transformation en format long
  df %>%
    pivot_longer(cols = all_of(outils_presents), names_to = "tool", values_to = "prediction") %>%
    mutate(Sample = nom_sample)
})

# 4. Calcul des statistiques cumulées
data_plot_global <- data_cumulee %>%
  mutate(
    Resultat = ifelse(tolower(trimws(prediction)) == "virus", "Sensibilité", "Oubli")
  ) %>%
  group_by(tool, Resultat) %>%
  summarise(n = n(), .groups = "drop_last") %>%
  mutate(Valeur = n / sum(n)) %>%
  ungroup()

# 5. Création du graphique global
p_global <- ggplot(data_plot_global, aes(x = reorder(tool, -Valeur * (Resultat == "Sensibilité")), 
                                         y = Valeur, 
                                         fill = Resultat)) +
  geom_col(position = "stack", width = 0.7, color = "white", linewidth = 0.2) +
  
  # Affiche le nombre total de contigs (somme des 4 échantillons)
  geom_text(aes(label = n), position = position_stack(vjust = 0.5), 
            size = 3.5, color = "white", fontface = "bold") +
  
  scale_fill_manual(values = c("Sensibilité" = "#27ae60", "Oubli" = "#e74c3c")) +
  scale_y_continuous(labels = percent_format(), expand = c(0,0)) +
  
  theme_minimal() +
  labs(
    title = "Performance Cumulée : S2, S7, S9, S13",
    subtitle = "Somme totale des détections (Sensibilité vs Oublis)",
    x = "Outils de détection", 
    y = "Proportion Globale (%)",
    fill = "Statut"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, size = 11, face = "bold", color = "black"),
    axis.title = element_text(face = "bold"),
    legend.position = "right",
    panel.grid.major.x = element_blank(),
    plot.title = element_text(size = 14, face = "bold", color = "#2c3e50")
  )

# 6. Sauvegarde en PDF (Vectoriel)
ggsave("PERF_GLOBALE_CUMULEE.pdf", plot = p_global, width = 10, height = 7, device = "pdf")

print(p_global)
cat("✅ Graphique cumulé généré : PERF_GLOBALE_CUMULEE.pdf\n")
