
# ==============================================================================
# SCRIPT R COMPLET : PERFORMANCE BARPLOT (MUTATION 100% UNIQUEMENT)
# ==============================================================================

# 1. INSTALLATION ET CHARGEMENT DES PACKAGES
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("scales")) install.packages("scales")

library(tidyverse)
library(scales)

# --- CONFIGURATION ---
# Remplace par le chemin correct vers ton dossier
input_folder <- "Viral_RefSeq_mutated" 

# Liste des fichiers mut100 uniquement
fichiers <- list.files(path = input_folder, pattern = "mut100\\.csv$", full.names = TRUE)

if (length(fichiers) == 0) {
  stop("❌ Erreur : Aucun fichier avec l'extension 'mut100.csv' n'a été trouvé dans le dossier : ", input_folder)
}

# 2. FONCTION DE CALCUL DES MÉTRIQUES (Harmonisée)
calculer_metrics_solo <- function(f) {
  df <- read_csv(f, show_col_types = FALSE)
  all_cols <- names(df)
  
  # Trouver la colonne Truth (insensible à la casse et aux espaces)
  truth_col <- all_cols[tolower(trimws(all_cols)) == "truth"]
  if (length(truth_col) == 0) return(NULL)
  
  df$Truth_clean <- tolower(trimws(as.character(df[[truth_col[1]]])))
  pred_cols <- names(df)[grep("prediction_", names(df))]
  
  map_df(pred_cols, function(col) {
    actual_pred <- tolower(trimws(as.character(df[[col]])))
    
    tp <- sum(df$Truth_clean == "virus" & actual_pred == "virus", na.rm = TRUE)
    fn <- sum(df$Truth_clean == "virus" & actual_pred == "autre", na.rm = TRUE)
    fp <- sum(df$Truth_clean != "virus" & actual_pred == "virus", na.rm = TRUE)
    tn <- sum(df$Truth_clean != "virus" & actual_pred == "autre", na.rm = TRUE)
    
    tibble(
      tool        = str_remove(col, "prediction_"),
      Sensitivity = ifelse((tp + fn) > 0, tp / (tp + fn), 0),
      Precision   = ifelse((tp + fp) > 0, tp / (tp + fp), 0),
      Specificity = ifelse((tn + fp) > 0, tn / (tn + fp), 1),
      F1          = ifelse((tp*2 + fp + fn) > 0, (2 * tp) / (2 * tp + fp + fn), 0)
    )
  })
}

# 3. TRAITEMENT ET CALCUL DES STATISTIQUES
message("📊 Analyse en cours sur ", length(fichiers), " fichiers...")
res_raw <- map_df(fichiers, calculer_metrics_solo)

# Calcul des moyennes (mean) et écarts-types (sd) par outil
res_stats <- res_raw %>%
  group_by(tool) %>%
  summarise(
    across(c(Sensitivity, Precision, Specificity, F1), 
           list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE))),
    .groups = "drop"
  ) %>%
  mutate(across(everything(), ~replace_na(.x, 0)))

# 4. PRÉPARATION DU FORMAT LONG POUR GGPLOT
# On trie les outils par F1-score moyen (du plus haut au plus bas)
ordre_outils <- res_stats %>%
  arrange(desc(F1_mean)) %>%
  pull(tool)

# Conversion des moyennes en format long
df_means <- res_stats %>%
  select(tool, ends_with("_mean")) %>%
  pivot_longer(-tool, names_to = "Metric", values_to = "Score", names_prefix = "mean_") %>%
  mutate(Metric = str_remove(Metric, "_mean"))

# Conversion des écarts-types en format long
df_sds <- res_stats %>%
  select(tool, ends_with("_sd")) %>%
  pivot_longer(-tool, names_to = "Metric", values_to = "SD", names_prefix = "sd_") %>%
  mutate(Metric = str_remove(Metric, "_sd"))

# Fusion des deux
df_final <- left_join(df_means, df_sds, by = c("tool", "Metric"))

# Appliquer l'ordre de tri et l'ordre des métriques
df_final$tool <- factor(df_final$tool, levels = ordre_outils)
df_final$Metric <- factor(df_final$Metric, levels = c("F1", "Precision", "Sensitivity", "Specificity"))

# 5. GÉNÉRATION DU GRAPHIQUE
couleurs_metriques <- c(
  "F1"          = "#E41A1C", # Rouge
  "Precision"   = "#377EB8", # Bleu
  "Sensitivity" = "#4DAF4A", # Vert
  "Specificity" = "#984EA3"  # Violet
)

p <- ggplot(df_final, aes(x = tool, y = Score, fill = Metric)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.8), width = 0.75) +
  geom_errorbar(aes(ymin = Score - SD, ymax = Score + SD), 
                position = position_dodge(width = 0.8), width = 0.25, alpha = 0.7) +
  scale_fill_manual(values = couleurs_metriques) +
  scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.1), expand = c(0, 0)) +
  theme_minimal() +
  labs(
    title = "Performance des outils sur séquences intactes (100% Identité)",
    subtitle = "Trié par F1-Score décroissant",
    x = "Outils de Bioinformatique",
    y = "Score (0-1)",
    fill = "Métriques"
  ) +
  theme(
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 11, color = "black"),
    axis.title = element_text(face = "bold"),
    legend.position = "top",
    legend.title = element_blank(),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank(),
    plot.title = element_text(hjust = 0.5, face = "bold"),
    plot.subtitle = element_text(hjust = 0.5)
  )

# 6. SAUVEGARDE
output_name <- paste0("Performance_100_percent_", format(Sys.time(), "%Y%m%d_%H%M"), ".png")
ggsave(output_name, p, width = 15, height = 8, dpi = 300)

message("✅ C'est fini ! Le graphique a été sauvegardé sous le nom : ", output_name)