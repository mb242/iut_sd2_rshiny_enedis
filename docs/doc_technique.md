# 📘 **Documentation Technique – Application R Shiny « Observatoire DPE – Nancy & Montpellier »**

---

## 1. **Présentation générale**

L’application est une interface Shiny permettant l’exploration interactive d’un dataset DPE issu de deux villes (Nancy & Montpellier).
Elle repose sur un pipeline complet : **chargement – nettoyage – transformation – visualisation – export**.

Les principaux blocs techniques sont :

* **UI** : `fluidPage()` avec thèmes, CSS personnalisé, panneau latéral, tabsets, KPI.
* **Serveur** : logique des filtres, graphiques (ggplot + plotly), KPI, transformations.
* **Données** : deux CSV publics fusionnés puis fortement nettoyés.
* **Exports** : `webshot2` pour PNG Plotly, `ggsave` pour ggplot.
* **Authentification custom** : UI HTML/CSS (pas de package externe).

---
### Installation et configuration

**Prérequis Système**

R : version 4.3.1
RStudio : version 4.3.3

## 2. **Dépendances et Packages**

### Packages utilisés

| Package         | Rôle                                         |
| --------------- | -------------------------------------------- |
| **shiny**       | Framework web                                |
| **dplyr**       | Nettoyage / manipulation                     |
| **ggplot2**     | Graphiques statiques                         |
| **plotly**      | Graphiques interactifs                       |
| **leaflet**     | Cartographie (option utilisée partiellement) |
| **DT**          | DataTables                                   |
| **stringr**     | Manipulation de chaînes                      |
| **htmlwidgets** | Sauvegarde widgets HTML                      |
| **webshot2**    | Export PNG de widgets                        |
| **shinythemes** | Thèmes visuels                               |

---

## 3. **Structure du Code**

### Fichier unique : `app.R`

Le fichier contient les blocs suivants :

```
1. Import des librairies
2. Fonctions utilitaires d’export PNG
3. Chargement & nettoyage des données
4. Construction UI
5. Styles CSS intégrés (auth + dashboard)
6. Logique Serveur
7. Lancement ShinyApp
```

---

## 4. **Pipeline de Données**

### 4.1 Chargement

```r
df_nancy <- read.csv2("https://raw.githubusercontent.com/mb242/iut_sd2_rshiny_enedis/main/data/logements_nancy.csv",
  header = TRUE,
  fileEncoding = "UTF-8"
))
df_montpellier <- read.csv2("https://raw.githubusercontent.com/mb242/iut_sd2_rshiny_enedis/main/data/logements_nancy.csv",
  header = TRUE,
  fileEncoding = "UTF-8"
)
df <- rbind(df_nancy, df_montpellier)
```

Les fichiers sont encodés en UTF-8 et contiennent des numériques sous forme textuelle.

### 4.2 Conversion des colonnes numériques

```r
df[num_cols] <- lapply(df[num_cols], function(x){
  x <- gsub(",", ".", x)
  as.numeric(x)
})
```

→ Gestion de virgule décimale et coercition.

### 4.3 Facteurs ordonnés

* Étiquettes DPE & GES (A→G)
* Période de construction (avant 1948 → après 2013)

### 4.4 Calculs additionnels

```r
df <- df %>% mutate(part_cout_chauffage = cout_chauffage / cout_total_5_usages)
```

### 4.5 Extraction lat/lon

Certaines bases fournissent un champ `X_geopoint` :

```r
lat = as.numeric(sub(",.*", "", X_geopoint))
lon = as.numeric(sub(".*,", "", X_geopoint))
```

---

## 5. **Interface Utilisateur**

### 5.1 Structure

```
fluidPage()
 ├─ <head> : styles CSS custom
 ├─ overlay d’authentification
 ├─ KPI (3 cartes)
 ├─ hud-main (bloc central)
      ├─ sidebarPanel (filtres)
      └─ mainPanel (onglets)
```

### 5.2 Système de filtres

* Ville : `Toutes` 
* Période de construction
* Énergie de chauffage
* Étiquettes DPE : checkboxGroup

---

## 6. **Logique Serveur**

### 6.1 Filtres

```r
observe({
  data <- df

  if (input$ville != "Toutes") data <- data[data$ville == input$ville, ]
  if (input$flag != "Tous") data <- data[data$flag == input$flag, ]
  ...
  
  if (!is.null(input$dpe_filtre)) 
      data <- data[data$etiquette_dpe %in% input$dpe_filtre, ]
  
  rv$data <- data
})
```

Toutes les visualisations utilisent `rv$data`.

---

## 7. **Indicateurs KPI**

Trois indicateurs dynamiques :

1. total des logements
2. nombre de passoires (DPE F/G)
3. consommation moyenne

Exemples :

```r
output$kpi_total_logements <- renderText(nrow(rv$data))

output$kpi_passoires <- renderText(sum(rv$data$etiquette_dpe %in% c("F","G")))

output$kpi_conso_moyenne <- renderText(round(mean(rv$data$conso_5_usages_par_m2_ep, na.rm=TRUE)))
```

---

## 8. **Visualisations**

### 8.1 Histogrammes DPE & GES

Version interactive :

```r
ggplot(...) %>% ggplotly()
```

Version statique :

```r
geom_bar(...) 
```

### 8.2 Graphiques comparatifs

Onglet « Comparaisons détaillées » :

* **Conso EP/m² vs période** (Plotly)
* **Coût chauffage vs DPE** (Plotly)
* **Surface vs coût chauffage** (ggplot statique)
* **Régression linéaire** avec choix des variables X/Y

### 8.3 Régression linéaire

```r
geom_smooth(method = "lm", formula = y ~ x)
```

→ Paramètres contrôlés depuis l’UI (variables X, Y, types de points, options de filtre).

---

## 9. **Export PNG des graphiques**

### Export Plotly

```r
save_plotly_png <- function(p, file){
  saveWidget(as_widget(p), htmlfile)
  webshot2::webshot(htmlfile, file)
}
```

### Export ggplot

```r
ggsave(file, plot = p)
```

Chaque graphique possède son bouton `downloadButton`.

---

## 10. **Authentification**

Même si elle n’utilise pas de package, la couche login repose sur :

* un overlay full-screen CSS
* une carte 2 colonnes (hero + formulaire)
* deux logos positionnés en fixed
* champs formels stylés
* déclenchement du panneau principal après validation (logique dans le serveur)

---

## 11. **CSS Avancé**

Le fichier contient deux blocs principaux intégrés via `tags$head()` :

1. **auth-panel.css**

   * grille responsive
   * dégradés
   * carte moderne
   * transitions

2. **hud-dashboard.css**

   * fond géométrique
   * cartes KPI
   * nav-tabs custom
   * DataTables remises en thème clair
   * boîtes de graphiques avec shadow

---

## 12. **Architecture Applicative Résumée**

```
app.R
 ├── DATA
 │     ├── chargement CSV
 │     ├── fusion df
 │     ├── nettoyage & conversions
 │     ├── création variables
 │     └── extraction lat/lon
 │
 ├── UI
 │     ├── login overlay
 │     ├── KPI
 │     ├── sidebar (filtres)
 │     ├── onglets graphiques
 │     └── CSS intégré
 │
 ├── SERVER
 │     ├── gestion login
 │     ├── filtrage réactif
 │     ├── calculs KPI
 │     ├── graphiques interactifs et statiques
 │     ├── régression linéaire
 │     └── exports PNG
 │
 └── Lancement shinyApp
```

---

## 13. **Ressources et Références**
- **Shiny** : https://shiny.posit.co/
- **Dépliant pour R** : https://rstudio.github.io/leaflet/
- **API ADEME** : https://data.ademe.fr/
- **dplyr** : https://dplyr.tidyverse.org/
- **plotly** : https://plotly.com/r/

  
* **Version** : 1.0
* **Dernière mise à jour** : 2025
* **Développeurs** : Aristide Tchetche, PHAM Thi Cam Tien, Elk-Fred MBAHOUKA


