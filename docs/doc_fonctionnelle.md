# Documentation Fonctionnelle

## OBSERVATOIRE DPE – Nancy & Montpellier

---

## Présentation de l’Application

Cette application web interactive permet d’analyser et visualiser les **Diagnostics de Performance Énergétique (DPE)** des logements des villes de **Nancy** et **Montpellier**.
Elle offre une exploration intuitive et dynamique des données, afin de mieux comprendre :

* La performance énergétique des logements
* Les comportements de consommation
* Les émissions de CO₂
* Les zones géographiques prioritaires
* Les corrélations entre caractéristiques et diagnostic DPE

Elle est principalement utilisée dans un cadre d’analyse énergétique territoriale et d’aide à la décision.

---

## Accès à l'application

L’accès nécessite une authentication pour sécuriser les données.

**Lien d'accès :** [Lien Shinyapps](https://mbahoutche.shinyapps.io/Rshinyapp/)

**Identifiants disponibles :**

* **Nom d'utilisateur :** Anthony
* **Mot de passe :** SARDELLITTI

Une fois connecté, l’utilisateur accède à un tableau de bord avec plusieurs onglets.

---

## Pages et Fonctionnalités

---

# 🏠 Page d’Accueil — Indicateurs Clés (KPI)

Cette page présente une synthèse globale des diagnostics à travers trois KPI :

* **🏘️ Total de logements analysés** : volume total des DPE intégrés
* **🔥 Logements “passoires énergétiques” (E, F, G)**
* **⚡ Consommation énergétique moyenne (kWh/m²/an)**

### Fonctionnalités supplémentaires

* Panneau de filtres global (ville, période, étiquette DPE…).
* Toutes les visualisations des autres onglets s’adaptent dynamiquement.

**Conseil :** Filtrez d’abord par ville pour réduire le volume et accélérer le rendu.

---

# 📊 Onglet 1 — Vue d’Ensemble

Cette page fournit une vue globale des diagnostics, avec deux modes :

### Mode Interactif

* Graphiques dynamiques
* Affichage de popups au survol
* Export PNG disponible

### Mode Statistique

* Résumés chiffrés et représentations synthétiques

**Astuce :** Survolez chaque barre pour afficher les valeurs exactes.

---

# ⚖️ Onglet 2 — Comparaison

Cet onglet permet de comparer visuellement les consommations, émissions et performances des logements.

Il propose :

### 1. **Boxplots des consommations selon l’étiquette DPE**

* Comprendre la distribution
* Visualiser les dispersions
* Comparer les groupes entre eux

### 2. **Nuage de points personnalisable (X vs Y)**

* Sélection libre de deux variables
* Analyse des corrélations
* Visualisation des tendances

### 3. **Régression linéaire**

* Affichage de la droite ajustée
* Affichage de l’équation
* Coefficient **R²**

**Conseil :** Appliquez des filtres pour améliorer le temps de calcul sur les gros jeux de données.

---

# 🔗 Onglet 3 — Évolution Cumulée

Analyse temporelle des consommations et coûts énergétiques :

* Évolution annuelle cumulée
* Comparaison des 5 usages (chauffage, éclairage…)
* Mise en évidence des tendances

---

# 🗺️ Onglet 4 — Carte Interactive

Cet onglet visualise de manière géographique l’ensemble des logements via une carte interactive.

### Fonctionnalités

* Affichage des logements de **Nancy** et **Montpellier**
* Couleurs selon étiquette DPE
* Zoom et navigation libre
* Popups détaillant :

  * Adresse
  * Étiquette DPE
  * Consommation énergétique

### Utilité

* Identifier les zones performantes
* Détecter les zones à risque énergétique
* Visualiser les clusters de passoires énergétiques

---

# 📑 Onglet 5 — Données

Cette section permet d’explorer et d’exporter les données brutes.

### Fonctionnalités

* Tableau interactif (filtrage, tri, recherche par colonne)
* Pagination (10 / 25 / 50 / 100 lignes)
* Export CSV
* Colonnes : adresses, caractéristiques, diagnostics, consommations, émissions…

---

# 🎛️ Filtres — Personnalisation de l’Analyse

Les filtres influencent **toutes les pages simultanément**.

### Filtres disponibles

* Ville
* Période / année DPE
* Étiquette DPE
* Type de logement
* Type d’énergie de chauffage
* Surface
* Consommation et émissions

**Conseil :** Combinez plusieurs filtres pour effectuer des analyses ciblées.

---

## Résumé des Apports

Cette application permet de :

* Explorer les diagnostics DPE de manière interactive
* Identifier les logements énergivores
* Comparer les consommations et corrélations
* Visualiser la répartition géographique
* Exporter graphiques et données
* Gagner en efficacité pour l’analyse énergétique territoriale

---

## Liens Utiles

* [📘 Dépôt GitHub](https://github.com/mb242/iut_sd2_rshiny_enedis/tree/main)
* [📄 Documentation fonctionnelle ](https://github.com/mb242/iut_sd2_rshiny_enedis/blob/main/docs/doc_fonctionnelle.md)
* [📄 Documentation technique ](https://github.com/mb242/iut_sd2_rshiny_enedis/blob/main/docs/doc_technique.md)
* [🔧 Code source shiny App](https://github.com/mb242/iut_sd2_rshiny_enedis/blob/main/app/app.R)
* [🖥️ Rapport ](https://github.com/mb242/iut_sd2_rshiny_enedis/blob/main/rapport/rapport_statistique.Rmd) 
* [📊 Rapports complémentaires](https://github.com/mb242/iut_sd2_rshiny_enedis/blob/main/rapport/rapport_statistique.html)

---

## Support

Pour toute question :
📩 **[admin@support.com](mailto:elk-fred.mbahouka@univ-lyon2.fr)**

