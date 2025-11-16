# --- PACKAGES --
#install.packages(c("httr", "jsonlite", "glue", "lubridate", "dplyr"))
library(httr)
library(jsonlite)
library(glue)
library(lubridate)
library(dplyr)

# ------------------------------------
# 1. Colonnes intéressantes
# ------------------------------------
colonnes_interessantes <- c(
  "numero_dpe",
  "date_reception_dpe",
  "date_etablissement_dpe",
  "date_visite_diagnostiqueur",
  "modele_dpe",
  "numero_dpe_remplace",
  "date_fin_validite_dpe",
  "version_dpe",
  "numero_dpe_immeuble_associe",
  "annee_construction",
  "type_batiment",
  "type_installation_chauffage",
  "type_installation_ecs",
  "periode_construction",
  "code_departement_ban",
  "code_insee_ban",
  "coordonnee_cartographique_x_ban",
  "coordonnee_cartographique_y_ban",
  "type_batiment",
  "periode_construction",
  "type_energie_principale_chauffage",
  "type_energie_principale_ecs",
  "cout_total_5_usages",
  "etiquette_dpe",
  "etiquette_ges",
  "classe_inertie_batiment",
  "cout_chauffage",
  "cout_ecs",
  "cout_refroidissement",
  "cout_eclairage",
  "code_postal_ban",
  "score_ban",
  "surface_habitable_logement",
  "conso_5_usages_par_m2_ep",
  "conso_5_usages_par_m2_ef",
  "conso_5_usages_ef",
  "conso_ecs_ep",
  "emission_ges_5_usages",
  "emission_ges_5_usages_par_m2",
  "qualite_isolation_murs",
  "qualite_isolation_plancher_bas",
  "qualite_isolation_enveloppe",
  "isolation_toiture",
  "inertie_lourde",
  "indicateur_confort_ete",
  "besoin_chauffage",
  "besoin_refroidissement",
  "besoin_ecs",
  "zone_climatique",
  "classe_altitude",
  "nom_commune_ban",
  "code_postal_ban",
  "code_insee_ban",
  "_geopoint"
)

colonnes_string <- paste(colonnes_interessantes, collapse = ",")

# ------------------------------------
# 2. EXISTANTS : fonction API
# ------------------------------------
get_data_existants <- function(base_url, codes_postaux) {
  df <- data.frame()
  
  for (code in codes_postaux) {
    params <- list(
      size  = 10000,
      select = colonnes_string,
      qs = glue(
        "code_postal_ban:{code}"
)
      )

    
    url_encoded <- modify_url(base_url, query = params)
    response    <- GET(url_encoded)
    
    if (response$status_code == 200) {
      content <- fromJSON(rawToChar(response$content), flatten = FALSE)
      total_logements <- content$total
      print(glue("[existant] Code postal {code} → total = {total_logements}"))
      
      if (total_logements <= 10000) {
        if (length(content$result) > 0) {
          df <- bind_rows(df, content$result)
        }
      } else {
        # Si > 10 000 → on découpe par année (2021–2025)
        for (annee in 2021:2025) {
          qs_year <- glue(
            "code_postal_ban:{code} ")
          
          params_year <- list(
            size  = 10000,
            select = colonnes_string,
            qs    = qs_year
          )
          
          url_year      <- modify_url(base_url, query = params_year)
          response_year <- GET(url_year)
          
          if (response_year$status_code == 200) {
            content_year <- fromJSON(rawToChar(response_year$content), flatten = FALSE)
            if (length(content_year$result) > 0) {
              df <- bind_rows(df, content_year$result)
            }
          } else {
            message(glue("Erreur API existants pour code {code} année {annee} : {response_year$status_code}"))
          }
        }
      }
    } else {
      message(glue("Erreur API existants pour code {code} : {response$status_code}"))
    }
  }
  
  df
}

# ------------------------------------
# 3. NEUFS : fonction API (requête simplifiée, SANS filtre énergie)
# ------------------------------------
get_data_neufs <- function(base_url, codes_postaux) {
  df <- data.frame()
  
  for (code in codes_postaux) {
    # Requête simple : juste CP + type_batiment
    params <- list(
      size = 10000,
      qs   = glue("code_postal_ban:{code}")
    )
    
    url_encoded <- modify_url(base_url, query = params)
    response    <- GET(url_encoded)
    
    if (response$status_code == 200) {
      content <- fromJSON(rawToChar(response$content), flatten = FALSE)
      total_logements <- content$total
      print(glue("[neuf] Code postal {code} → total = {total_logements}"))
      
      if (length(content$result) > 0) {
        tmp <- bind_rows(content$result)
        
        # On garde seulement les colonnes intéressantes qui existent vraiment
        colonnes_communes <- intersect(colonnes_interessantes, names(tmp))
        tmp <- tmp[, colonnes_communes, drop = FALSE]
        
        df <- bind_rows(df, tmp)
      }
    } else {
      message(glue("Erreur API NEUFS pour code {code} : {response$status_code}"))
      # pour debugger, tu peux décommenter la ligne suivante :
      # message(rawToChar(response$content))
    }
  }
  
  df
}

# ------------------------------------
# 4. Config : URLs + codes postaux
# ------------------------------------
base_url_existants <- "https://data.ademe.fr/data-fair/api/v1/datasets/dpe03existant/lines"
base_url_neufs     <- "https://data.ademe.fr/data-fair/api/v1/datasets/dpe02neuf/lines"

codes_postaux_nancy <- "54000"
codes_postaux_mtp   <- "34000"

# ------------------------------------
# 5. Nancy : existants + neufs
# ------------------------------------
df_existants_nancy <- get_data_existants(base_url_existants, codes_postaux_nancy) %>%
  mutate(ville = "Nancy", flag = "existant")

df_neufs_nancy <- get_data_neufs(base_url_neufs, codes_postaux_nancy) %>%
  mutate(ville = "Nancy", flag = "neuf")

logements_nancy <- bind_rows(df_existants_nancy, df_neufs_nancy)

# ------------------------------------
# 6. Montpellier : existants + neufs
# ------------------------------------
df_existants_mtp <- get_data_existants(base_url_existants, codes_postaux_mtp) %>%
  mutate(ville = "Montpellier", flag = "existant")

df_neufs_mtp <- get_data_neufs(base_url_neufs, codes_postaux_mtp) %>%
  mutate(ville = "Montpellier", flag = "neuf")

logements_mtp <- bind_rows(df_existants_mtp, df_neufs_mtp)

# ------------------------------------
# 7. Fusion & export
# ------------------------------------
logements_nancy_mtp <- bind_rows(logements_nancy, logements_mtp)

# renommage dataframe
df <- logements_nancy_mtp

#write.csv2(
# logements_nancy_mtp,
#  file = "C:/Users/2018e/Downloads/logements_nancy_montpellier.csv",
#  row.names = FALSE,
# fileEncoding = "UTF-8"
#)

# petit contrôle
print(table(logements_nancy_mtp$ville, logements_nancy_mtp$flag))





