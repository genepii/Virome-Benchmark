# ==============================================================================
# SCRIPT : MATRICE MOCK RECTIFIÉE (TAILLES MAXIMISÉES & TAXONOMIE OFFICIELLE)
# ==============================================================================

if (!require("tidyverse")) install.packages("tidyverse")
library(tidyverse)

input_file <- "NEW_MASTER_ASSIGNATION_STANDARDIZED.tsv"

if (!file.exists(input_file)) {
  stop(paste("❌ Erreur : Le fichier", input_file, "est introuvable !"))
}

df <- read.delim(input_file, sep="\t", header=TRUE, stringsAsFactors = FALSE)

# 1. Filtrage sur le Mock et nettoyage des NA
df_mock <- df %>%
  mutate(Condition = str_extract(Echantillon, "^[A-Z]+")) %>%
  filter(Condition == "MOCK") %>%
  rename(Truth = Truth_taxonomique) %>%
  mutate(across(c(Truth, Cenote, Diamond, geNomad, Kraken2, PhaBox), 
                ~ ifelse(is.na(.x) | .x == "" | .x == "NA", "inconnu", .x))) %>%
  pivot_longer(
    cols = c(Cenote, Diamond, geNomad, Kraken2, PhaBox), 
    names_to = "Outil", 
    values_to = "Prediction"
  ) %>%
  # 🔥 CORRECTION MAJUSCULES : Application sur la vérité et les prédictions
  mutate(across(c(Truth, Prediction), ~ case_when(
    .x == "hsv1" ~ "HSV1",
    .x == "vrs"  ~ "VRS",
    .x == "ms2"  ~ "MS2",
    TRUE         ~ .x
  )))

# 2. Structure 9x9 stricte (les clés d'origine du dataframe pour le mapping)
categories_identiques <- c("HSV1", "VRS", "adenovirus", "influenza", "rhinovirus", "MS2", "phage", "autre_virus", "inconnu")

df_mock_final <- df_mock %>%
  mutate(
    Truth      = if_else(Truth %in% categories_identiques, Truth, "inconnu"),
    Prediction = if_else(Prediction %in% categories_identiques, Prediction, "inconnu")
  )

# 3. Dictionnaire de traduction officielle pour les axes (Famille + Virus)
labels_officiels <- c(
  "HSV1"        = "Herpesviridae (HSV1)",
  "VRS"         = "Paramyxoviridae (VRS)",
  "adenovirus"  = "Adenoviridae (Adénovirus)",
  "influenza"   = "Orthomyxoviridae (Influenza)",
  "rhinovirus"  = "Picornaviridae (Rhinovirus)",
  "MS2"         = "Fiersviridae (MS2)",
  "phage"       = "Phage",
  "autre_virus" = "Autre Virus",
  "inconnu"     = "Non classifié"
)

# Application des niveaux et des étiquettes propres sous forme de facteurs
df_mock_final$Truth      <- factor(df_mock_final$Truth, levels = rev(categories_identiques), labels = rev(labels_officiels))
df_mock_final$Prediction <- factor(df_mock_final$Prediction, levels = categories_identiques, labels = labels_officiels)

# Comptage après application des facteurs pour conserver le carré parfait
df_mock_final <- df_mock_final %>% count(Outil, Truth, Prediction)

# 4. Création du graphique
p <- ggplot(df_mock_final, aes(x = Prediction, y = Truth, fill = n)) +
  geom_tile(color = "white", linewidth = 0.2) +
  # 🔥 LISIBILITÉ : Chiffres gras à l'intérieur des cases (size = 5.5)
  geom_text(aes(label = ifelse(n > 0, n, "")), color = "#000000", fontface = "bold", size = 5.5) + 
  facet_wrap(~ Outil, ncol = 2) +
  scale_fill_gradient(low = "#EBF5FB", high = "#2E86C1", na.value = "white", name = "Nb Contigs") + 
  
  # Forçage de l'affichage des lignes/colonnes à 0 (Carré parfait)
  scale_y_discrete(drop = FALSE) +
  scale_x_discrete(drop = FALSE) +
  
  theme_bw() +
  labs(
    title = "Matrice de Confusion Taxonomique - Échantillons MOCK",
    subtitle = "Dataset Clinique Réel - Alignement strict des axes et des familles",
    x = "Famille Prédite par l'Outil",
    y = "Famille Réelle (Vérité Terrain)"
  ) +
  theme(
    # 🔥 INTENSITÉ TEXTE MAXIMISÉE : Noir pur (#000000) et gras partout
    text = element_text(face = "bold", color = "#000000"),
    
    # Titre principal et sous-titre
    plot.title = element_text(size = 24, face = "bold", color = "#000000", hjust = 0.5, margin = margin(b=10)),
    plot.subtitle = element_text(size = 15, face = "italic", color = "grey30", hjust = 0.5, margin = margin(b=20)),
    
    # Titres majeurs des axes X et Y
    axis.title.x = element_text(size = 18, face = "bold", color = "#000000", margin = margin(t=15)),
    axis.title.y = element_text(size = 18, face = "bold", color = "#000000", margin = margin(r=15)),
    
    # Étiquettes des catégories sur les axes (Italique gras pour le style scientifique des familles)
    axis.text.x = element_text(angle = 45, hjust = 1, size = 13, face = "bold.italic", color = "#000000"),
    axis.text.y = element_text(size = 13, face = "bold.italic", color = "#000000"),
    
    # Bandeaux des facettes au-dessus de chaque matrice (Noms des outils)
    strip.background = element_rect(fill = "grey95", color = "black", linewidth = 0.5),
    strip.text = element_text(color = "#000000", size = 18, face = "bold", margin = margin(t=10, b=10)),
    
    # Bloc de la légende
    legend.title = element_text(size = 15, face = "bold", color = "#000000"),
    legend.text  = element_text(size = 13, face = "bold", color = "#000000"),
    
    legend.position = "right",
    panel.grid = element_blank()
  )

# Exportations (Taille légèrement augmentée à 16x14 pour laisser de la place aux étiquettes longues)
ggsave("MATRICE_INTERSECTION_MOCK_CORRIGEE.pdf", plot = p, width = 16, height = 14, device = "pdf")
ggsave("MATRICE_INTERSECTION_MOCK_CORRIGEE.png", plot = p, width = 16, height = 14, dpi = 300)

print(p)
