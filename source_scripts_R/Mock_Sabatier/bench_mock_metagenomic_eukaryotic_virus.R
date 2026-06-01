# ==============================================================================
# SCRIPT R REVISÉ : BENCHMARK MULTI-FICHIERS SANS COLONNE TRUTH INITIALE
# ==============================================================================

# --- 1. SETUP & CONFIGURATION ---
if (!require("tidyverse")) install.packages("tidyverse")
library(tidyverse)

pdf_rapport_nom <- "RAPPORT_COMPLET_BENCHMARK.pdf"

palette_custom <- c(
  "Score F1"    = "#E41A1C", 
  "Précision"   = "#377EB8", 
  "Sensibilité" = "#4DAF4A", 
  "Spécificité" = "#984EA3"
)

# --- 2. FONCTION DE CALCUL DES MÉTRIQUES ---
calc_metrics <- function(df, col) {
  tp <- sum(df[[col]] == "virus" & df$Truth_binaire == "virus", na.rm = TRUE)
  fp <- sum(df[[col]] == "virus" & df$Truth_binaire == "autre", na.rm = TRUE)
  tn <- sum(df[[col]] == "autre" & df$Truth_binaire == "autre", na.rm = TRUE)
  fn <- sum(df[[col]] == "autre" & df$Truth_binaire == "virus", na.rm = TRUE)
  
  prec <- ifelse((tp + fp) > 0, tp / (tp + fp), 0)
  sens <- ifelse((tp + fn) > 0, tp / (tp + fn), 0)
  spec <- ifelse((tn + fp) > 0, tn / (tn + fp), 0)
  f1   <- ifelse((prec + sens) > 0, 2 * (prec * sens) / (prec + sens), 0)
  
  return(data.frame(Precision = prec, Sensitivity = sens, Specificity = spec, F1 = f1))
}

# --- 3. CHARGEMENT DYNAMIQUE ET CONSTRUCTION DE LA VÉRITÉ TERRAIN ---
print("🔍 Recherche des fichiers de concaténation...")
fichiers_tsv <- list.files(pattern = "^CONCATENATION_.*\\.tsv$")

if (length(fichiers_tsv) == 0) {
  stop("❌ Erreur : Aucun fichier 'CONCATENATION_*.tsv' trouvé dans le dossier courant !")
}

message(paste("📥", length(fichiers_tsv), "fichiers détectés. Calcul de la vérité terrain..."))

df_master <- map_df(fichiers_tsv, function(fichier) {
  # Extraction Condition et Réplicat depuis le nom (ex: CONCATENATION_HSV-E1.tsv)
  nom_brut <- str_remove(fichier, "^CONCATENATION_") %>% str_remove("\\.tsv$")
  parts <- str_split(nom_brut, "-")[[1]]
  
  cond_extraite <- parts[1]
  rep_extrait  <- parts[2]
  
  df_temp <- read_tsv(fichier, show_col_types = FALSE)
  
  # CRÉATION DE TRUTH_BINAIRE : Basé sur la colonne pred_Kraken2
  # Si Kraken2 dit virus = VRAI virus. Sinon = autre.
  df_temp <- df_temp %>% 
    mutate(
      Condition = cond_extraite,
      Replicat = rep_extrait,
      Truth_binaire = if_else(pred_Kraken2 == "virus", "virus", "autre")
    )
  
  return(df_temp)
})

# Détection des colonnes d'outils (ex: pred_DMC, pred_DVF...)
tools <- names(df_master)[str_detect(names(df_master), "^pred_")]
message(paste("⚙️ Outils détectés :", paste(str_remove(tools, "pred_"), collapse = ", ")))

conditions <- unique(df_master$Condition)
replicates <- unique(df_master$Replicat)

# --- 4. CALCULS DES SCORES PAR RÉPLICAT ---
print("📊 Calcul des métriques de performance...")
all_data <- map_df(conditions, function(cond) {
  map_df(replicates, function(rep) {
    
    df_sub <- df_master %>% filter(Condition == cond, Replicat == rep)
    if (nrow(df_sub) == 0) return(NULL)
    
    map_df(tools, function(t) {
      res <- calc_metrics(df_sub, t)
      res$Tool  <- str_remove(t, "pred_")
      res$Group <- cond
      res$Rep   <- rep
      return(res)
    })
  })
})

# --- 5. CALCUL DES MOYENNES ET ÉCART-TYPES ---
stats_grouped <- all_data %>%
  group_by(Group, Tool) %>%
  summarise(
    across(c(F1, Precision, Sensitivity, Specificity), 
           list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE)), 
           .names = "{.col}_{.fn}"),
    .groups = 'drop'
  )

stats_grouped[is.na(stats_grouped)] <- 0

# --- 6. GÉNÉRATION DES GRAPHES PDF ---
pdf(pdf_rapport_nom, width = 11, height = 7, useDingbats = FALSE)
groupes <- unique(stats_grouped$Group)

for (g in groupes) {
  
  data_plot <- stats_grouped %>%
    filter(Group == g) %>%
    pivot_longer(
      cols = starts_with(c("F1_", "Precision_", "Sensitivity_", "Specificity_")), 
      names_to = c("Metric", "Stat"), 
      names_sep = "_"
    ) %>%
    pivot_wider(names_from = Stat, values_from = value) %>%
    mutate(Metric = case_when(
      Metric == "F1"          ~ "Score F1",
      Metric == "Precision"   ~ "Précision",
      Metric == "Sensitivity" ~ "Sensibilité",
      Metric == "Specificity" ~ "Spécificité",
      TRUE                    ~ Metric
    )) %>%
    mutate(Metric = factor(Metric, levels = c("Score F1", "Précision", "Sensibilité", "Spécificité")))
  
  # Tri par F1 décroissant
  ordre_outils <- data_plot %>% 
    filter(Metric == "Score F1") %>% 
    arrange(desc(mean)) %>% 
    pull(Tool)
  
  data_plot$Tool <- factor(data_plot$Tool, levels = ordre_outils)

  p <- ggplot(data_plot, aes(x = Tool, y = mean, fill = Metric)) +
    geom_bar(stat = "identity", position = position_dodge(0.8), color = "black", linewidth = 0.3) +
    geom_errorbar(aes(ymin = pmax(0, mean - sd), ymax = pmin(1, mean + sd)), 
                  position = position_dodge(0.8), width = 0.25, linewidth = 0.4) +
    scale_fill_manual(values = palette_custom) +
    scale_y_continuous(limits = c(0, 1.05), breaks = seq(0, 1, 0.1), labels = scales::label_number(accuracy = 0.1)) +
    theme_minimal() +
    labs(title = paste("Performance des outils - Condition :", g),
         subtitle = "Moyenne +/- Écart-type (Classé par F1 décroissant)",
         y = "Score Moyen", x = "Outils") +
    theme(
      axis.text.x   = element_text(angle = 45, hjust = 1, face = "bold", color = "black", size = 14), 
      axis.text.y   = element_text(color = "black", size = 13),                                      
      axis.title.x  = element_text(face = "bold", size = 15, margin = margin(t = 10)),                
      axis.title.y  = element_text(face = "bold", size = 15, margin = margin(r = 10)),                
      legend.text   = element_text(size = 13, face = "bold"),                                       
      plot.title    = element_text(face = "bold", size = 18),                                       
      plot.subtitle = element_text(size = 13),                                                      
      legend.position = "top",
      legend.title    = element_blank()
    )

  file_output <- paste0("GRAPH_BENCHMARK_", g, ".pdf")
  ggsave(file_output, plot = p, width = 11, height = 7, device = "pdf", useDingbats = FALSE)
  
  print(p)
  message(paste("✅ Graphique généré pour le groupe :", g))
}

dev.off()

write_csv(stats_grouped, "RESUME_STATISTIQUES_PAR_GROUPE.csv")
message(paste("🚀 Terminé ! Le rapport complet est disponible ici :", pdf_rapport_nom))

