library(tidyverse)

# ==========================================
# 1. CONFIGURATION
# ==========================================
# On utilise "." pour pointer sur le dossier défini par setwd()
dossier_source <- "." 

chemins <- list(
  Cenote  = file.path(dossier_source, "assigned_CENOTE.tsv"),
  Diamond = file.path(dossier_source, "assigned_DIAMOND.tsv"),
  geNomad = file.path(dossier_source, "assigned_GENOMAD.tsv"),
  Kraken2 = file.path(dossier_source, "assigned_KRAKEN2.tsv"),
  PhaBOX  = file.path(dossier_source, "assigned_PHABOX.tsv")
)

# ==========================================
# 2. CHARGEMENT ET NETTOYAGE
# ==========================================
charger_pour_confusion <- function(nom_outil, path) {
  if(!file.exists(path)) stop(paste("❌ Fichier introuvable :", path))
  
  read_tsv(path, col_types = cols(.default = "c", Identite = "d")) %>%
    filter(Identite == 100) %>% 
    mutate(Outil = nom_outil) %>%
    select(Outil, Truth_Family, Famille) %>%
    mutate(
      Famille_Pred = case_when(
        Famille %in% c("not_detected", "0", NA) ~ "Non détecté",
        TRUE ~ Famille
      )
    )
}

df_confusion <- map2_df(names(chemins), chemins, ~charger_pour_confusion(.x, .y))

# Liste des familles cibles
familles_interet <- c("Ackermannviridae", "Demerecviridae", "Straboviridae", 
                      "Mimiviridae", "Chimalliviridae", "Caudoviricetes_incertae_sedis")

df_heatmap <- df_confusion %>%
  filter(Truth_Family %in% familles_interet) %>%
  mutate(Famille_Pred = ifelse(Famille_Pred %in% c(familles_interet, "Non détecté"), 
                               Famille_Pred, "Autres Familles")) %>%
  group_by(Outil, Truth_Family, Famille_Pred) %>%
  summarise(n = n(), .groups = "drop") %>%
  group_by(Outil, Truth_Family) %>%
  mutate(percentage = n / sum(n) * 100)

# ==========================================
# 3. HARMONISATION DES AXES (LA DIAGONALE)
# ==========================================

# Ordre unique pour les axes (sans Non Classifié qui est absent de tes données)
ordre_commun <- c(
  "Ackermannviridae", 
  "Demerecviridae", 
  "Straboviridae", 
  "Mimiviridae", 
  "Chimalliviridae", 
  "Caudoviricetes_incertae_sedis", 
  "Autres Familles", 
  "Non détecté"
)

# Appliquer l'ordre à l'axe X (Prédictions)
df_heatmap$Famille_Pred <- factor(df_heatmap$Famille_Pred, levels = ordre_commun)

# Appliquer l'ordre à l'axe Y (Vérité) - Inversé pour que la diagonale parte du haut à gauche
df_heatmap$Truth_Family <- factor(df_heatmap$Truth_Family, levels = rev(ordre_commun))

df_heatmap$Outil <- factor(df_heatmap$Outil, levels = c("Kraken2", "Diamond", "PhaBOX", "geNomad", "Cenote"))

# ==========================================
# 4. GRAPHIQUE FINAL (TEXTES AGRANDIS ET NOIR/GRAS)
# ==========================================

p <- ggplot(df_heatmap, aes(x = Famille_Pred, y = Truth_Family, fill = percentage)) +
  geom_tile(color = "grey90", linewidth = 0.2) +
  # Chiffres à l'intérieur des cases agrandis (size = 5.5)
  geom_text(aes(label = ifelse(percentage > 0.5, sprintf("%.0f%%", percentage), "")), 
            color = ifelse(df_heatmap$percentage > 45, "white", "black"), 
            fontface = "bold", size = 5.5) +
  facet_wrap(~Outil, ncol = 2) +
  scale_fill_gradient(low = "white", high = "#08306B", name = "% Assigné") +
  theme_bw() +
  labs(
    title = "Matrice de Confusion Taxonomique (Diagonale)",
    subtitle = "Données Intactes (100% ID) - Alignement parfait des axes",
    x = "Famille Prédite (Outil)",
    y = "Famille Réelle (Vérité Terrain)"
  ) +
  theme(
    # Titres (Agrandis)
    plot.title = element_text(face = "bold", size = 26, color = "black", hjust = 0.5, margin = margin(b=10)),
    plot.subtitle = element_text(face = "italic", size = 16, color = "black", hjust = 0.5, margin = margin(b=20)),
    
    # Axe X - Noms des familles prédites (Inclinés pour la lisibilité)
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", color = "black", size = 14),
    axis.title.x = element_text(face = "bold", color = "black", size = 16, margin = margin(t=15)),
    
    # Axe Y - Noms des familles réelles
    axis.text.y = element_text(face = "bold", color = "black", size = 14),
    axis.title.y = element_text(face = "bold", color = "black", size = 16, margin = margin(r=15)),
    
    # Titre des facettes (Noms des outils)
    strip.text = element_text(face = "bold", size = 20, color = "black", margin = margin(t=10, b=10)),
    
    # Légende (Agrandie)
    legend.text = element_text(face = "bold", size = 13, color = "black"),
    legend.title = element_text(face = "bold", size = 15, color = "black"),
    
    panel.grid = element_blank()
  )

# Génération des noms de fichiers avec horodatage pour éviter d'écraser tes anciens tests
nom_complet_pdf <- file.path(dossier_source, paste0("Confusion_Matrix_Diagonal_", format(Sys.time(), "%Hh%M"), ".pdf"))
nom_complet_png <- str_replace(nom_complet_pdf, ".pdf", ".png")

# Sauvegarde en PDF (Haute qualité vectorielle pour ton rapport/soutenance)
ggsave(nom_complet_pdf, p, width = 18, height = 14, device = "pdf")

# Sauvegarde en PNG
ggsave(nom_complet_png, p, width = 18, height = 14, dpi = 300)

cat("✅ Tout le code a été exécuté avec succès ! Les fichiers PNG et PDF ont été générés.\n")
