# ==============================================================================
# SCRIPT : ABONDANCE RELATIVE ÉQUITABLE (MISE À JOUR TAXONOMIE OFFICIELLE)
# ==============================================================================

# --- 1. CONFIGURATION INITIALE ---
if (!require("tidyverse")) install.packages("tidyverse")
if (!require("ggh4x")) install.packages("ggh4x")

library(tidyverse)
library(ggh4x)

fichier_entree = "NEW_MASTER_ASSIGNATION_STANDARDIZED.tsv"

# --- 2. CHARGEMENT DES DONNÉES ---
if (!file.exists(fichier_entree)) {
  stop(paste("❌ Erreur : Le fichier", fichier_entree, "est introuvable !"))
}

df = read.delim(fichier_entree, sep="\t", header=TRUE, stringsAsFactors = FALSE)

# --- 3. PRÉPARATION ET FUSION DE L'HUMAIN ---
df_plot = df %>%
  mutate(
    Condition = str_extract(Echantillon, "^[A-Z]+"),
    Batch     = str_extract(Echantillon, "[1-3]$")
  ) %>%
  pivot_longer(
    cols = c(Cenote, Diamond, geNomad, Kraken2, PhaBox, Truth_taxonomique),
    names_to = "Outil", 
    values_to = "Taxonomie"
  ) %>%
  # TRADUCTION : 'Truth_taxonomique' devient 'Vérité' pour le graphique
  mutate(Outil = if_else(Outil == "Truth_taxonomique", "Vérité", Outil)) %>%
  # FUSION : Fusion de 'humain' dans 'inconnu' pour l'équité du benchmark
  mutate(Taxonomie = if_else(Taxonomie == "humain", "inconnu", Taxonomie)) %>%
  # CORRECTION MAJUSCULES : Passage en majuscules pour VRS, MS2 et HSV1
  mutate(Taxonomie = case_when(
    Taxonomie == "hsv1" ~ "HSV1",
    Taxonomie == "vrs"  ~ "VRS",
    Taxonomie == "ms2"  ~ "MS2",
    TRUE                ~ Taxonomie
  ))

# --- 4. CONFIGURATION DE LA LÉGENDE AVEC SYNCHRONISATION DES COULEURS ---
niveaux_cibles = c("HSV1", "VRS", "adenovirus", "influenza", "rhinovirus", "MS2", "phage", "autre_virus", "inconnu")
df_plot$Taxonomie = factor(df_plot$Taxonomie, levels = niveaux_cibles)

# Palette de couleurs optimisée (le gris doux délimite parfaitement les contours)
palette_complete = c(
  "HSV1"        = "#2ECC71",   # Vert vif
  "VRS"         = "#943126",   # Rouge foncé / Bordeaux
  "adenovirus"  = "#E74C3C",   # Rouge vif
  "influenza"   = "#3498DB",   # Bleu ciel
  "rhinovirus"  = "#2E4053",   # Bleu nuit / Ardoise
  "MS2"         = "#F1C40F",   # Jaune d'or éclatant
  "phage"       = "#E67E22",   # Orange ambré
  "autre_virus" = "#8E44AD",   # Violet Prune / Pourpre
  "inconnu"     = "#F8F9F9"    # Gris très doux (ex-inconnu, rendu visible par les bordures)
)

# Dictionnaire de la légende révisé selon ton tableau clinique et tes souhaits
labels_legende = c(
  "HSV1"        = "Herpesviridae (HSV1)",
  "VRS"         = "Paramyxoviridae (VRS)",          # Ajusté selon ton tableau de référence
  "adenovirus"  = "Adenoviridae (Adénovirus)",
  "influenza"   = "Orthomyxoviridae (Influenza)",
  "rhinovirus"  = "Picornaviridae (Rhinovirus)",
  "MS2"         = "Fiersviridae (MS2)",
  "phage"       = "Phage",
  "autre_virus" = "Autre Virus",                   # Raccourci sans spécifier les familles
  "inconnu"     = "Non classifié"                  # "inconnu" devient "Non classifié"
)

# --- 5. CALCUL DES ABONDANCES RELATIVES ---
df_comptages = df_plot %>%
  count(Condition, Outil, Batch, Taxonomie) %>%
  group_by(Condition, Outil, Batch) %>%
  mutate(Relative_Abundance = n / sum(n)) %>%
  ungroup()

# Ordre d'affichage des facettes d'outils
df_comptages$Outil = factor(df_comptages$Outil, levels = c("Vérité", "Cenote", "Diamond", "geNomad", "Kraken2", "PhaBox"))

# --- 6. CRÉATION DU GRAPHIQUE ---
p = ggplot(df_comptages, aes(x = Batch, y = Relative_Abundance, fill = Taxonomie)) +
  # Structure des barres améliorée : contour fin gris moyen pour isoler le bloc "Non classifié"
  geom_bar(stat = "identity", width = 0.85, position = position_stack(reverse = TRUE), color = "grey60", linewidth = 0.1) +
  facet_nested(. ~ Condition + Outil, scales = "free_x", space = "free_x") +
  scale_fill_manual(values = palette_complete, labels = labels_legende) +
  theme_minimal() +
  labs(
    y = "Abondance Virale Relative", 
    x = "Lots / Réplicats (1, 2, 3)", 
    fill = "TAXONOMIE"
  ) +
  theme(
    # TEXTES EN GRAS ET NOIR PUR (#000000)
    text = element_text(face = "bold", color = "#000000"),
    
    # Textes des bandeaux de facettes (Conditions et Outils)
    strip.background = element_rect(fill = "grey95", color = "black", linewidth = 0.5),
    strip.text = element_text(size = 16, face = "bold", color = "#000000"),
    
    # Titres majeurs des axes (X et Y)
    axis.title = element_text(size = 22, face = "bold", color = "#000000"),
    
    # Labels des réplicats (1, 2, 3) et graduations de l'axe Y
    axis.text.x = element_text(size = 16, face = "bold", color = "#000000"),
    axis.text.y = element_text(size = 15, face = "bold", color = "#000000"),
    
    # Bloc complet de la légende
    legend.title = element_text(size = 17, face = "bold", color = "#000000"),
    legend.text  = element_text(size = 15, face = "bold.italic", color = "#000000"), # Italic pour le style scientifique des familles
    
    # Espacements et lignes de délimitation
    panel.spacing = unit(0.3, "lines"),
    panel.grid = element_blank(),
    axis.line = element_line(color = "#000000", linewidth = 1.4),
    legend.position = "right"
  )

# --- 7. EXPORTATIONS ---
horodatage = format(Sys.time(), "%Hh%M")
nom_base   = paste0("Benchmark_Abondance_Officiel_", horodatage)

ggsave(paste0(nom_base, ".pdf"), plot = p, width = 24, height = 11, device = "pdf")
ggsave(paste0(nom_base, ".png"), plot = p, width = 24, height = 11, dpi = 300)

print(p)
cat(paste0("\n✅ Graphique corrigé généré avec succès ! \n Fichier : ", nom_base, ".pdf\n"))
