# OBSERVATOIRE DPE – NANCY & MONTPELLIER

> **Tableau de bord interactif** pour analyser et visualiser les Diagnostics de Performance Énergétique (DPE) des logements des villes de **Nancy** et **Montpellier**.

---

## Table des Matières

- [À Propos](#à-propos)
- [Fonctionnalités](#fonctionnalités)
- [Démo](#démo)
- [Installation](#installation)
- [Utilisation](#utilisation)
- [Architecture](#architecture)
- [Technologies](#technologies)
- [Documentation](#documentation)
- [Contributeurs](#contributeurs)



## À Propos

### Contexte du Projet

Cette application Shiny a été développée dans le cadre d’un **projet d’analyse des DPE** pour les villes de **Nancy** et **Montpellier**, en partenariat entre l’**IUT** et **Enedis**.

Elle permet de visualiser finement la performance énergétique des logements, de repérer les **passoires énergétiques** (étiquettes F et G) et de croiser de nombreuses variables (surface, période de construction, type d’énergie, coût de chauffage, etc.).

### Objectifs

L’application vise à :

- Visualiser la **répartition des étiquettes DPE et GES** sur les deux villes étudiées  
- Mettre en évidence les **passoires énergétiques** (F et G)  
- Analyser les **consommations et coûts énergétiques** :
  - Conso 5 usages EP/m²
  - Conso 5 usages EF
  - Coût de chauffage
- Étudier les liens entre :
  - Période de construction et consommation
  - Surface habitable et coût de chauffage
  - Variables numériques via corrélogramme et régression linéaire
- Cartographier les logements selon leur DPE pour **localiser les zones sensibles**

### Source des Données

Les données proviennent de l'**ADEME** (Agence de l'Environnement et de la Maîtrise de l'Énergie) : 
- [API DPE v2 - Logements existants](https://data.ademe.fr/datasets/dpe-v2-logements-existants)
- [API DPE v2 - Logements neufs](https://data.ademe.fr/datasets/dpe-v2-logements-neufs)



## Fonctionnalités

### Niveau Standard

- Tableau de bord avec **5 onglets thématiques**
Interface type HUD futuriste avec fond personnalisé et charte graphique CSS

- **3 KPI dynamiques** : Vue d'ensemble ,   Comparaisons détaillées , Evolution cumuléé , Carte intéractive , données

- **5 types de graphiques intéracticfs et statiques** : histogramme, barres, boxplot, nuage de points , corrélogramme

- **Carte interactive Leaflet** avec clustering des marqueurs

- **Filtres multi-critères** : Ville, type de logement , Période de construction, type d'érnergie, étiquette DPE 



### Niveau Intermédiaire

- **Export des graphiques** en PNG
- **Export des données** filtrées en CSV, XLSX
- **Calcul du coefficient de corrélation** entre variables numériques
- **Régression linéaire simple** avec droite de tendance
- **Corrélogramme** 

### Niveau Expert
- **Charte graphique CSS** personnalisée et inséré dans **app.R**
- **Authentification utilisateur** avec mots de passe (Identifiant : Anthony ; Mot de passe : SARDELLITTI)


## Démo

### Application en Ligne
**URL de déploiement** :  https://mbahoutche.shinyapps.io/Rshinyapp/

### Vidéo de Démonstration
**YouTube** : https://www.youtube.com/watch?v=rNTOMFlwerI

### Structure du Projet


```

│
├── app/                              # Code source de l’application Shiny
│   ├── app.R                         # Fichier principal Shiny
│   ├── www/                          
│   │   ├── Enedis.png
│   │   ├── IUT.png
│   │   └── Fond d'écran shiny.png
|
├── data/                             # Données locales accessibles à l’app
│   └── logements_nancy_montpellier.csv
│
├── data_preparation/                 # Scripts de préparation et d’analyse des données
│   └── extraction_api.R
│
├── rapport/                             
│   ├── rapport_statistique.Rmd       # Le script de rapport Rmarkdown
│   └── rapport_statistique.html/pdf  # Version "knit" en HTML ou pdf
|
├── docs/                             # Documentation du projet
│   ├── doc_technique.md              # Documentation technique
│   └── doc_fonctionnelle.md             # Documentation fonctionnelle
|
└── README.md   # README principal du dépôt avec le lien de la vidéo démo et de la démo déployé.

```

## Documentation

### Documents Disponibles

| Document                 | Description                        | Public cible          |
|--------------------------|------------------------------------|-----------------------|
| [README.md]              | Vue d'ensemble du projet           | Tous                  |
| [doc_fonctionnelle.md]   | Guide utilisateur complet          | Utilisateurs finaux   |
| [doc_technique.md]       | Détails techniques et architecture | Développeurs          |

### Ressources Externes

- [Documentation Shiny](https://shiny.posit.co/)
- [Leaflet pour R](https://rstudio.github.io/leaflet/)
- [Plotly R](https://plotly.com/r/)
- [shinyauthr Guide](https://github.com/PaulC91/shinyauthr)

---

## Contributeurs

### Participants :  

  - **[PHAM Thi Cam Tien](mailto:thi-cam-tien.pham2@univ-lyon2.fr)**
  - **[Aristide Tchetche](mailto:aristide.tchetche@univ-lyon2.fr)**
  - **[Elk-Fred MBAHOUKA](<a href="mailto:elk-fred.mbahouka@univ-lyon2.fr?subject=Contact&body=Bonjour%2C%20je%20vous%20écris%20concernant...">
  Envoyer un mail
</a>
)**
    
### Client

- **ENEDIS** - Demandeur du projet




