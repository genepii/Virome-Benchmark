# Benchmarking Pipeline for Viral Detection

Ce dépôt centralise l'ensemble des scripts et pipelines de benchmarking développés pour l'évaluation et la comparaison d'outils de prédiction et de détection virale.

L'objectif principal est d'évaluer, tester et comparer l'efficacité de différents logiciels bioinformatiques à l'aide de jeux de données contrôlés (RefSeq et jeux de données simulés/*Mock*).

---

## 📂 Structure du Projet

Le projet est structuré de manière à suivre l'ordre logique du pipeline de benchmarking, depuis la préparation des données brutes jusqu'à la visualisation finale des performances :

* **`dataset_refseq_preparation/`** : Scripts dédiés à la préparation et au filtrage du jeu de données de référence RefSeq (notamment pour l'élimination de la contamination bactérienne par les prophages via le filtre pVOG).
* **`Déréplication-Assemblage-Mapping/`** : Étapes d'assemblage et de mapping des données *Mock* (conversion des *reads* bruts en contigs artificiels et élimination des séquences redondantes).
* **`scripts_Bash/`** : Contient les scripts d'exécution, de soumission et d'automatisation des différents outils de prédiction virale testés.
* **`classification_binaire/`** : Scripts et analyses dédiés à la distinction simple (classification binaire) entre Virus et Autre.
* **`classification_taxonomique/`** : Scripts dédiés à l'assignation taxonomique au niveau de Famille des séquences virales détectées par les outils.
* **`source_scripts_R/`** : Code source R utilisé pour l'analyse statistique, le calcul des métriques de performance (précision, sensibilité, spécificité, score F1, ) et les visualisations graphiques (`ggplot2`).
* **`Results/`** : Dossier de sortie contenant les matrices de confusion calculées ainsi que les figures prêtes pour la présentation des résultats.

---

## 🚀 Zoom sur le script de filtrage pVOG

Pour garantir la robustesse du benchmark, les génomes bactériens servant de contrôle négatif doivent être rigoureusement exempts de prophages. Le script de batch automatisé permet d'exclure tout contig possédant un ratio de gènes viraux supérieur ou égal à 30 %.

### Environnement et Dépendances
Le pipeline s'appuie sur une image Singularity (`virome-bench-v6.sif`) embarquant toutes les dépendances requises pour l'analyse.
