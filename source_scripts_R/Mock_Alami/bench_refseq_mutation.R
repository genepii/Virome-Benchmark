
# ==============================================================================
# SCRIPT R FINAL INTÉGRAL
# ==============================================================================

if (!require("tidyverse")) install.packages("tidyverse")
if (!require("scales")) install.packages("scales")
if (!require("ggrepel")) install.packages("ggrepel")

library(tidyverse)
library(scales)
library(ggrepel)

# 1. CONFIGURATION
input_folder <- "Viral_RefSeq_mutated" 
timestamp    <- format(Sys.time(), "%Hh%M")
fichiers     <- list.files(path = input_folder, pattern = "^COMBINED_.*\\.csv$", full.names = TRUE)

if (length(fichiers) == 0) stop("❌ Aucun fichier 'COMBINED_' trouvé !")

# 2. FONCTION DE CALCUL
calculer_metrics_solo <- function(f) {
  fname  <- basename(f)
  mut_id <- as.numeric(str_extract(fname, "(?<=mut)\\d+"))
  df <- read_csv(f, show_col_types = FALSE)
  
  all_cols <- names(df)
  truth_col_name <- all_cols[tolower(trimws(all_cols)) == "truth"]
  if (length(truth_col_name) == 0) return(NULL)
  
  df$Truth_clean <- tolower(trimws(as.character(df[[truth_col_name[1]]])))
  pred_cols <- names(df)[grep("prediction_", names(df))]
  
  res <- map_df(pred_cols, function(col) {
    actual_pred <- tolower(trimws(as.character(df[[col]])))
    
    tp <- sum(df$Truth_clean == "virus" & actual_pred == "virus", na.rm = TRUE)
    fn <- sum(df$Truth_clean == "virus" & actual_pred == "autre", na.rm = TRUE)
    fp <- sum(df$Truth_clean != "virus" & actual_pred == "virus", na.rm = TRUE)
    tn <- sum(df$Truth_clean != "virus" & actual_pred == "autre", na.rm = TRUE)
    
    rec <- ifelse((tp + fn) > 0, tp / (tp + fn), 0)
    pre <- ifelse((tp + fp) > 0, tp / (tp + fp), 0)
    spe <- ifelse((tn + fp) > 0, tn / (tn + fp), 1)
    
    tibble(
      tool = str_remove(col, "prediction_"),
      mutation = mut_id,
      Recall = rec,
      Precision = pre,
      Specificite = spe,
      F1_Score = ifelse((pre + rec) > 0, 2 * (pre * rec) / (pre + rec), 0),
      VP = tp,
      FP = fp
    )
  })
  rm(df); gc() 
  return(res)
}

# 3. EXÉCUTION
res_global <- map_df(fichiers, calculer_metrics_solo)

res_stats <- res_global %>%
  group_by(mutation, tool) %>%
  summarise(
    across(c(Recall, Precision, Specificite, F1_Score, VP, FP), 
           list(mean = ~mean(.x, na.rm = TRUE), sd = ~sd(.x, na.rm = TRUE))), 
    .groups = "drop"
  ) %>%
  mutate(across(ends_with("_sd"), ~replace_na(.x, 0)))

# 4. FONCTION DE GÉNÉRATION DE GRAPHES
generer_graph <- function(df, metrique, titre, label_type) {
  col_mean <- paste0(metrique, "_mean")
  col_sd   <- paste0(metrique, "_sd")
  
  mes_couleurs <- c(
    "diamond" = "#E41A1C", "cenotetaker3" = "#377EB8", "dmc" = "#4DAF4A", 
    "dvf" = "#984EA3", "genomad" = "#FF7F00", "kraken" = "#A65628", 
    "phabox" = "#F781BF", "viralm" = "#00CED1", "viralverify" = "#999999", 
    "virsorter2" = "#DEDE00"
  )

  p <- ggplot(df, aes(x = mutation, y = !!sym(col_mean), color = tool, group = tool)) +
    geom_errorbar(aes(ymin = !!sym(col_mean) - !!sym(col_sd), 
                      ymax = !!sym(col_mean) + !!sym(col_sd)), 
                  width = 1.2, color = "black", linewidth = 0.5, alpha = 0.8) +
    geom_line(linewidth = 1.3) + 
    geom_point(size = 2.5) +
    scale_x_reverse(breaks = seq(100, 50, -5), limits = c(105, 48)) +
    scale_y_continuous(labels = percent_format(), limits = c(-0.05, 1.15), breaks = seq(0, 1, 0.2)) +
    scale_color_manual(values = mes_couleurs) + 
    theme_bw() +
    labs(title = titre, x = "% Identité (Mutation)", y = paste(metrique, "(%)"), color = "Outils") +
    theme(text = element_text(color = "black", face = "bold"),
          plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
          axis.text = element_text(size = 10, color = "black"),
          legend.position = "bottom")

  if (label_type == "FP_once") {
    p <- p + geom_label_repel(data = filter(df, mutation == 100),
                              aes(label = paste0("FP: ", round(FP_mean, 0))),
                              nudge_x = 5, direction = "y", size = 3, fontface = "bold.italic")
  } else if (label_type == "VP_all") {
    p <- p + geom_text(aes(label = round(VP_mean, 0)), vjust = -1.8, size = 2.5, fontface = "bold", check_overlap = TRUE)
  }
  return(p)
}

# 5. GÉNÉRATION
p1 <- generer_graph(res_stats, "Recall", "1. Sensibilité (Recall)", "VP_all")
p2 <- generer_graph(res_stats, "Precision", "2. Précision", "FP_once")
p3 <- generer_graph(res_stats, "Specificite", "3. Spécificité", "none")
p4 <- generer_graph(res_stats, "F1_Score", "4. F1-Score", "none")

ggsave(paste0("1_Recall_", timestamp, ".png"), p1, width = 12, height = 8)
ggsave(paste0("2_Precision_", timestamp, ".png"), p2, width = 12, height = 8)
ggsave(paste0("3_Specificite_", timestamp, ".png"), p3, width = 12, height = 8)
ggsave(paste0("4_F1_Score_", timestamp, ".png"), p4, width = 12, height = 8)


# Option A : Sauvegarder chaque graphique dans un fichier PDF séparé
ggsave(paste0("1_Recall_", timestamp, ".pdf"), p1, width = 12, height = 8, device = "pdf")
ggsave(paste0("2_Precision_", timestamp, ".pdf"), p2, width = 12, height = 8, device = "pdf")
ggsave(paste0("3_Specificite_", timestamp, ".pdf"), p3, width = 12, height = 8, device = "pdf")
ggsave(paste0("4_F1_Score_", timestamp, ".pdf"), p4, width = 12, height = 8, device = "pdf")