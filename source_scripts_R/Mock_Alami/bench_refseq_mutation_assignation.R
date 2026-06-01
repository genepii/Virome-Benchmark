setwd("C:/Users/ALAMIEX/Desktop/Projet_Soufiane/Workflow_R/viral_RefSeq_mutated_assignation")

library(tidyverse)
library(scales)

# ==========================================
# 1. CONFIGURATION
# ==========================================
dossier_source <- "." 

chemins <- list(
  Cenote  = file.path(dossier_source, "assigned_CENOTE.tsv"),
  Diamond = file.path(dossier_source, "assigned_DIAMOND.tsv"),
  geNomad = file.path(dossier_source, "assigned_GENOMAD.tsv"),
  Kraken2 = file.path(dossier_source, "assigned_KRAKEN2.tsv"),
  PhaBOX  = file.path(dossier_source, "assigned_PHABOX.tsv")
)

# ==========================================
# 2. CHARGEMENT ET TRAITEMENT
# ==========================================
charger_donnees <- function(nom, path) {
  if(!file.exists(path)) stop(paste("❌ Fichier introuvable :", path))
  read_tsv(path, col_types = cols(.default = "c", Identite = "d")) %>%
    mutate(Outil = nom) %>%
    select(Outil, Replicat, Identite, Contig_ID, Truth_Family, Famille)
}

df_tous_outils <- map2_df(names(chemins), chemins, charger_donnees)

# Création de la barre "Vérité" (Truth)
df_verite <- df_tous_outils %>%
  filter(Outil == "Diamond") %>% 
  mutate(Outil = "Vérité", Famille = Truth_Family) %>%
  select(Outil, Replicat, Identite, Contig_ID, Famille)

# Fusion et filtre 10%
df_global <- bind_rows(df_tous_outils %>% select(-Truth_Family), df_verite) %>%
  filter(Identite %in% c(100, 90, 80, 70, 60, 50))

# Catégorisation avec traduction en français
df_plot <- df_global %>%
  mutate(Categorie = case_when(
    Famille %in% c("not_detected", "Not_Detected", "0", NA) ~ "Non Détecté",
    Famille %in% c("Unknown", "Unassigned", "Unclassified", "unclassified", "None") ~ "Non Classifié",
    Famille == "Caudoviricetes_incertae_sedis" ~ "Caudoviricetes_incertae_sedis",
    Famille == "Ackermannviridae" ~ "Ackermannviridae",
    Famille == "Demerecviridae"   ~ "Demerecviridae",
    Famille == "Straboviridae"    ~ "Straboviridae",
    Famille == "Mimiviridae"      ~ "Mimiviridae",
    Famille == "Chimalliviridae"  ~ "Chimalliviridae",
    TRUE ~ "Autres Familles"
  ))

# Facteurs : Ordre des catégories (en français)
niveaux_categories <- c("Non Détecté", "Non Classifié", "Autres Familles", 
                        "Caudoviricetes_incertae_sedis", "Ackermannviridae", 
                        "Demerecviridae", "Straboviridae", "Mimiviridae", "Chimalliviridae")

df_plot$Categorie <- factor(df_plot$Categorie, levels = niveaux_categories)

# Ordre des outils (avec "Vérité" au lieu de "Truth")
df_plot$Outil <- factor(df_plot$Outil, 
                        levels = c("Vérité", "Kraken2", "Diamond", "PhaBOX", "geNomad", "Cenote"))

# Inversion de l'ordre des facettes (De 100 à 50)
df_plot$Identite <- factor(df_plot$Identite, levels = c(100, 90, 80, 70, 60, 50))

# ==========================================
# 3. GRAPHIQUE (TEXTES AGRANDIS, NOIR ET GRAS)
# ==========================================

mes_couleurs <- c(
  "Non Détecté"                   = "#F2F2F2",
  "Non Classifié"                 = "#BDBDBD",
  "Autres Familles"               = "#1F78B4",
  "Caudoviricetes_incertae_sedis" = "#E31A1C",
  "Ackermannviridae"              = "#33A02C",
  "Demerecviridae"                = "#6A3D9A",
  "Straboviridae"                 = "#FF7F00",
  "Mimiviridae"                   = "#FDBF6F",
  "Chimalliviridae"               = "#FB9A99"
)

p <- ggplot(df_plot, aes(x = Outil, fill = Categorie)) +
  geom_bar(position = "fill", color = "white", linewidth = 0.05) +
  # --- TRAIT SÉPARATEUR ---
  geom_vline(xintercept = 1.5, linetype = "dashed", color = "black", linewidth = 1.2) +
  facet_wrap(~Identite, ncol = 3, 
             labeller = labeller(Identite = function(x) paste0(x, "% d'Identité"))) +
  scale_y_continuous(labels = percent) +
  scale_fill_manual(values = mes_couleurs) +
  theme_minimal() +
  labs(
    title = "Cohérence de l'Assignation Taxonomique Virale",
    x = NULL, y = "Proportion (%)", fill = "Taxonomie"
  ) +
  theme(
    # --- TEXTE NOIR, GRAS ET AGRANDI ---
    # Titre principal (passé de 20 à 26)
    plot.title = element_text(face = "bold", size = 26, hjust = 0.5, color = "black", margin = margin(b = 20)),
    
    # Axe X - Noms des outils (passé de 13 à 16)
    axis.text.x = element_text(angle = 45, hjust = 1, face = "bold", size = 16, color = "black"),
    
    # Axe Y - Pourcentages (passé de 12/14 à 15/18)
    axis.text.y = element_text(face = "bold", size = 15, color = "black"),
    axis.title.y = element_text(face = "bold", size = 18, color = "black", margin = margin(r = 15)),
    
    # Titres des facettes ex: "100% d'Identité" (passé de 15 à 20)
    strip.text = element_text(face = "bold", size = 20, color = "black", margin = margin(b = 10, t = 10)),
    
    # Légende (passé de 12/13 à 15/17)
    legend.text = element_text(face = "bold", size = 15, color = "black"),
    legend.title = element_text(face = "bold", size = 17, color = "black"),
    
    legend.position = "bottom",
    legend.box.margin = margin(t = 20),
    panel.grid.major.x = element_blank(),
    panel.grid.minor = element_blank()
  ) +
  # Ajustement de l'espace des légendes pour éviter les chevauchements
  guides(fill = guide_legend(nrow = 2, byrow = TRUE))

# Sauvegarde PNG
ggsave(file.path(dossier_source, "Benchmark_Consistency_Final.png"), p, width = 18, height = 13)

cat("✅ Graphique généré avec des textes plus grands !")

# Chemin et sauvegarde PDF
nom_pdf <- file.path(dossier_source, paste0("Benchmark_Consistency_Final_", format(Sys.time(), "%Hh%M"), ".pdf"))
ggsave(nom_pdf, p, width = 18, height = 13, device = "pdf")
