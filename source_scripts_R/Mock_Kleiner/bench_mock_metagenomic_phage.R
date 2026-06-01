# ==============================================================================
# ANALYSE UNIFIÉE : MOYENNE + ÉCART-TYPE (U80, U81, U82) - SAVE PDF
# ==============================================================================

if (!require("tidyverse")) install.packages("tidyverse")
library(tidyverse)

# 1. Configuration
setwd("C:/Users/ALAMIEX/Desktop/Projet_Soufiane/Workflow_R/mock_metaG")

# Palette de couleurs imposée
couleurs_metriques <- c(
  "F1"          = "#E41A1C", # Rouge
  "Precision"   = "#377EB8", # Bleu
  "Sensitivity" = "#4DAF4A", # Vert
  "Specificity" = "#984EA3"  # Violet
)

# 2. Fichiers
fichiers <- c("U80" = "mock_metagenomic_U80.csv", 
              "U81" = "mock_metagenomic_U81.csv", 
              "U82" = "mock_metagenomic_U82.csv")

lire_donnees_robuste <- function(chemin) {
  df <- read.delim(chemin, stringsAsFactors = FALSE)
  if(ncol(df) <= 1) df <- read.csv(chemin, stringsAsFactors = FALSE)
  if(ncol(df) <= 1) df <- read.csv2(chemin, stringsAsFactors = FALSE)
  return(df)
}

# 3. Calcul des métriques par Dataset
df_metrics <- map_df(fichiers, lire_donnees_robuste, .id = "Dataset") %>%
  pivot_longer(cols = contains("prediction"), names_to = "outil", values_to = "pred") %>%
  mutate(outil = str_replace(outil, ".*prediction_", "")) %>%
  group_by(Dataset, outil) %>%
  summarise(
    tp = sum(Ground_Truth == "virus" & pred == "virus", na.rm = TRUE),
    fp = sum(Ground_Truth == "autre" & pred == "virus", na.rm = TRUE),
    tn = sum(Ground_Truth == "autre" & pred == "autre", na.rm = TRUE),
    fn = sum(Ground_Truth == "virus" & pred == "autre", na.rm = TRUE),
    .groups = "drop"
  ) %>%
  mutate(
    Sensitivity = ifelse((tp + fn) > 0, tp / (tp + fn), 0),
    Precision   = ifelse((tp + fp) > 0, tp / (tp + fp), 0),
    Specificity = ifelse((tn + fp) > 0, tn / (tn + fp), 0),
    F1          = ifelse((Precision + Sensitivity) > 0, 2 * (Precision * Sensitivity) / (Precision + Sensitivity), 0)
  )

# 4. CALCUL DE LA MOYENNE ET DE L'ÉCART-TYPE (SD) DES TROIS DATASETS
df_stats <- df_metrics %>%
  group_by(outil) %>%
  summarise(
    across(c(F1, Precision, Sensitivity, Specificity), 
           list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE))),
    .groups = "drop"
  )

# 5. PRÉPARATION DU GRAPHIQUE (Format Long pour ggplot)
data_plot <- df_stats %>%
  pivot_longer(cols = -outil, 
               names_to = c("Metric", "Stat"), 
               names_sep = "_") %>%
  pivot_wider(names_from = Stat, values_from = value)

# Tri des outils par F1 moyen décroissant
ordre_outils <- data_plot %>% filter(Metric == "F1") %>% arrange(desc(mean)) %>% pull(outil)
data_plot$outil <- factor(data_plot$outil, levels = ordre_outils)
data_plot$Metric <- factor(data_plot$Metric, levels = c("F1", "Precision", "Sensitivity", "Specificity"))

# 6. GÉNÉRATION DU GRAPHIQUE UNIQUE AVEC BARRES D'ERREUR
p <- ggplot(data_plot, aes(x = outil, y = mean, fill = Metric)) +
  # Barres de la moyenne
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), color = "black", linewidth = 0.3) +
  # Barres d'écart-type (Error Bars)
  geom_errorbar(aes(ymin = pmax(0, mean - sd), ymax = pmin(1, mean + sd)), 
                position = position_dodge(width = 0.8), width = 0.25, linewidth = 0.4) +
  scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.2)) +
  scale_fill_manual(values = couleurs_metriques) +
  theme_minimal() +
  labs(title = "Benchmark Global : Performance Moyenne (U80-81-82)",
       subtitle = "Moyenne +/- Écart-type | Classé par F1-Score",
       x = "Outils de prédiction", 
       y = "Score Moyen", 
       fill = "Indicateurs") +
  theme(legend.position = "top",
        axis.text.x = element_text(angle = 45, hjust = 1, face = "bold"),
        panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank())

# Affichage
print(p)

# 7. SAUVEGARDE EN PDF (Pour Inkscape)
timestamp <- format(Sys.time(), "%Hh%M")
ggsave(paste0("Benchmark_Moyenne_SD_Global_", timestamp, ".pdf"), plot = p, width = 12, height = 7, device = "pdf")

message("✅ Graphique de la moyenne avec écart-type généré en PDF !")
