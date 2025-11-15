# app.R ------------------------------------------------------------------------
# ====== Librairies ======
library(shiny)
library(dplyr)
library(ggplot2)
library(leaflet)
library(DT)
library(stringr)
library(shinythemes)
library(plotly)        # interactivité
library(htmlwidgets)   # sauvegarde des widgets html
library(webshot2)      # capture PNG de widgets html
# library(mapview)     # plus besoin, on exporte la carte avec webshot2

# ====== Utilitaires d'export ======
save_plotly_png <- function(p, file, vwidth = 1200, vheight = 800, scale = 2){
  htmlfile <- tempfile(fileext = ".html")
  htmlwidgets::saveWidget(plotly::as_widget(p), file = htmlfile, selfcontained = TRUE)
  webshot2::webshot(htmlfile, file = file, vwidth = vwidth, vheight = vheight, zoom = scale)
}
save_ggplot_png <- function(p, file, width = 12, height = 8, dpi = 150){
  ggplot2::ggsave(filename = file, plot = p, width = width, height = height, dpi = dpi)
}





# -------------------------------------------------------------------
# 1. CHARGEMENT & NETTOYAGE DES DONNEES
# -------------------------------------------------------------------
df_nancy <- read.csv2(
  "https://raw.githubusercontent.com/mb242/iut_sd2_rshiny_enedis/main/data/logements_nancy.csv",
  header = TRUE,
  fileEncoding = "UTF-8"
)
#Lien vers le fichier de données stocké sur GitHub


df_montpellier <- read.csv2(
  "https://raw.githubusercontent.com/mb242/iut_sd2_rshiny_enedis/main/data/logements_montpellier.csv",
  header = TRUE, fileEncoding = "UTF-8"
)

df <- rbind(df_nancy, df_montpellier)

# Colonnes numériques stockées en texte avec virgule
num_cols <- c(
  "conso_5_usages_ef","cout_eclairage","cout_total_5_usages","besoin_chauffage",
  "cout_chauffage","conso_5_usages_par_m2_ep","conso_5_usages_par_m2_ef","besoin_ecs",
  "emission_ges_5_usages","emission_ges_5_usages_par_m2",
  "coordonnee_cartographique_x_ban","coordonnee_cartographique_y_ban",
  "surface_habitable_logement","cout_ecs","conso_5_usages_ef"
)
num_cols <- intersect(num_cols, names(df))
df[num_cols] <- lapply(df[num_cols], function(x){
  if (is.numeric(x)) return(x)
  x2 <- gsub(",", ".", x); suppressWarnings(as.numeric(x2))
})

# Variables num. (régression)
num_vars  <- names(df)[sapply(df, is.numeric)]
default_x <- if ("surface_habitable_logement" %in% num_vars) "surface_habitable_logement" else num_vars[1]
default_y <- if ("cout_chauffage" %in% num_vars) "cout_chauffage" else num_vars[min(2, length(num_vars))]

# Facteurs ordonnés
dpe_levels <- c("A","B","C","D","E","F","G")
df$etiquette_dpe <- factor(df$etiquette_dpe, levels = dpe_levels, ordered = TRUE)
df$etiquette_ges <- factor(df$etiquette_ges, levels = dpe_levels, ordered = TRUE)

# Palette DPE
dpe_colors <- c("A"="#009900","B"="#66CC33","C"="#FFCC33","D"="#FF9900",
                "E"="#FF6600","F"="#FF3300","G"="#CC0000")

# Période de construction ordonnée
if ("periode_construction" %in% names(df)) {
  df$periode_construction <- factor(
    df$periode_construction,
    levels = c("avant 1948","1948-1974","1975-1977","1978-1982",
               "1983-1988","1989-2000","2001-2005","2006-2012","après 2013"),
    ordered = TRUE
  )
}

# Part du coût chauffage
if (all(c("cout_chauffage","cout_total_5_usages") %in% names(df))) {
  df <- df %>% mutate(part_cout_chauffage = cout_chauffage / cout_total_5_usages)
}

# Lat / Lon depuis X_geopoint
if ("X_geopoint" %in% names(df)) {
  df <- df %>% mutate(
    lat = suppressWarnings(as.numeric(sub(",.*", "", X_geopoint))),
    lon = suppressWarnings(as.numeric(sub(".*,", "", X_geopoint)))
  )
}

# -------------------------------------------------------------------
# 2. UI
# -------------------------------------------------------------------
# Expose le dossier images 'test' (logos + fond)
# -> on met le même "prefix" que ce qui est utilisé dans les paths (test/ia.jpg, test/logo_...)

addResourcePath("www",(" https://github.com/mb242/iut_sd2_rshiny_enedis/blob/main/app/www")) 



ui <- fluidPage(
  theme = shinytheme("flatly"),
  
  # ===== AUTH v2 (héros + panneau) =====
  tags$head(tags$style(HTML("
/* Overlay */
.login-overlay{
  position:fixed; inset:0; z-index:9999;
  background: radial-gradient(1200px 600px at 20% 20%, #e9d5ff 0%, transparent 60%),
              radial-gradient(1000px 500px at 80% 30%, #bfdbfe 0%, transparent 60%),
              #f4f6fb;
  display:flex; align-items:center; justify-content:center; padding:40px;
}
/* Logos coins */
.brand-left,.brand-right{
  position:fixed; top:20px; width:150px !important; height:auto !important;
  object-fit:contain; z-index:10000; filter:drop-shadow(0 2px 6px rgba(0,0,0,.15));
}
.brand-left{ left:20px; } .brand-right{ right:20px; }

/* Carte 2 colonnes */
.auth-card{
  width:min(1100px,95vw); display:grid; grid-template-columns: 1.1fr 1fr;
  border-radius:22px; overflow:hidden; box-shadow:0 24px 80px rgba(9,14,40,.18); background:#fff;
}
.auth-hero{
  padding:42px 48px; background:linear-gradient(135deg,#312e81,#1e3a8a);
  color:#fff; display:flex; flex-direction:column; justify-content:center;
}
.auth-hero .tag{
  display:inline-flex; align-items:center; gap:8px;
  background:rgba(255,255,255,.12); border:1px solid rgba(255,255,255,.25);
  padding:8px 12px; border-radius:999px; font-size:14px; letter-spacing:.06em;
}
.auth-title{ margin:16px 0 10px 0; font-weight:800; line-height:1.1; font-size:40px; }
.auth-sub{ opacity:.95; font-size:16px; max-width:46ch }

/* Panneau form */
.auth-form{ background:#ffffff; padding:36px 32px; display:flex; flex-direction:column; justify-content:center; }
.auth-form h2{ font-weight:800; font-size:22px; color:#0f172a; margin:0 0 14px 0; }
.auth-form .note{ color:#64748b; font-size:13px; margin-bottom:18px; }
.auth-form .login-field{ margin-bottom:12px; }
.auth-form .login-label{ display:block; font-weight:600; color:#334155; margin-bottom:6px; }
.auth-form .btn-submit .btn{ width:100%; background:linear-gradient(135deg,#60a5fa,#6366f1); border:none; }
.auth-form .btn-submit .btn:hover{ background:linear-gradient(135deg,#93c5fd,#818cf8); }
.auth-foot{ margin-top:10px; text-align:center; color:#64748b; font-size:12px }

/* Responsive */
@media (max-width: 900px){
  .auth-card{ grid-template-columns:1fr; }
  .auth-hero{ padding:28px; } .auth-title{ font-size:32px; }
  .brand-left,.brand-right{ width:84px !important; }
  .brand-left{ left:16px; } .brand-right{ right:16px; }
}
"))),
  
  # ===== Styles HUD/KPI =====
  tags$head(tags$style(HTML("
html, body { 
  height: 100%;
  background:
    linear-gradient(rgba(2,6,23,.55), rgba(2,6,23,.55)),
    url('test/ia.jpg') center / cover no-repeat fixed !important;
}
.welcome-title {
  text-align:center; font-size:32px; font-weight:900; text-transform:uppercase; letter-spacing:1.5px;
  background:linear-gradient(90deg,#0ea5e9,#6366f1); -webkit-background-clip:text; -webkit-text-fill-color:transparent;
  text-shadow:0 0 12px rgba(99,102,241,0.45); margin-bottom:22px;
}
.hud-bg {
  min-height:100vh; padding:30px 20px 40px; color:#e5e7eb;
  background:
    linear-gradient(rgba(2,6,23,.55), rgba(2,6,23,.55)),
    url('test/ia.jpg') center / cover no-repeat fixed !important;
  position:relative;
}
.hud-bg::before{ content:''; position:fixed; inset:0;
  background-image:linear-gradient(rgba(15,23,42,0.35) 1px,transparent 1px),
                   linear-gradient(90deg, rgba(15,23,42,0.35) 1px,transparent 1px);
  background-size:80px 80px; pointer-events:none; z-index:-1; }
.hud-main{ background:rgba(15,23,42,0.92); border-radius:18px; padding:20px 24px 28px;
  box-shadow:0 0 0 1px rgba(56,189,248,0.35), 0 18px 45px rgba(15,23,42,0.95);color: #2563EB;}
.hud-title h2{ color:#e5e7eb; text-transform:uppercase; letter-spacing:2px; font-weight:600; }

/* KPI */
.kpi-box{ display:flex; align-items:center; padding:15px; border-radius:12px; color:#fff;
  margin-bottom:15px; box-shadow:0 0 18px rgba(15,23,42,0.9); border:1px solid rgba(148,163,184,0.4);}
.kpi-blue{background:linear-gradient(135deg,#0ea5e9,#22c1c3);}
.kpi-red{background:linear-gradient(135deg,#f97316,#ef4444);}
.kpi-purple{background:linear-gradient(135deg,#6366f1,#a855f7);}
.kpi-icon{ font-size:36px; margin-right:15px; }
.kpi-text p{ margin:0; font-size:11px; text-transform:uppercase; letter-spacing:1.5px; }
.kpi-text h3{ margin:3px 0 0; font-weight:700; }

/* DataTable clair */
table.dataTable { background-color:#ffffff !important; color:#111827 !important; }
table.dataTable thead th, table.dataTable tfoot th { color:#111827 !important; border-color:#e5e7eb !important; background:#ffffff !important; }
table.dataTable tbody td { border-color:#e5e7eb !important; }
table.dataTable thead input{
  background:#ffffff !important; border:1px solid #9ca3af !important; color:#111827 !important; border-radius:6px !important; padding:3px 6px !important;
}
.dataTables_wrapper .dataTables_length label,
.dataTables_wrapper .dataTables_filter label { color:#111827 !important; font-weight:500 !important; }
.dataTables_wrapper .dataTables_length select,
.dataTables_wrapper .dataTables_filter input{
  background:#ffffff !important; border:1px solid #9ca3af !important; color:#111827 !important; border-radius:6px !important; padding:3px 8px !important;
}
.dataTables_wrapper .dataTables_length select:focus,
.dataTables_wrapper .dataTables_filter input:focus { outline:none !important; box-shadow:0 0 0 2px #60a5fa !important; }
.dt-buttons .dt-button{
  background:#e0e7ff !important; border:1px solid #6366f1 !important; color:#1e3a8a !important;
  border-radius:6px !important; padding:4px 10px !important; margin-right:6px !important; font-weight:600 !important;
}
.dt-buttons .dt-button:hover{ background:#c7d2fe !important; }
.dataTables_wrapper .dataTables_info { color:#111827 !important; }
.dataTables_wrapper .dataTables_paginate .paginate_button{
  background:#ffffff !important; border:1px solid #9ca3af !important; color:#111827 !important; border-radius:6px !important; margin:0 2px !important;
}
.dataTables_wrapper .dataTables_paginate .paginate_button.current,
.dataTables_wrapper .dataTables_paginate .paginate_button.current:hover{
  background:#e5e7eb !important; color:#111827 !important;
}
.dataTables_scrollBody{ background:#ffffff !important; }
table.dataTable.stripe tbody tr.odd { background-color:#f9fafb !important; }
table.dataTable.stripe tbody tr.even{ background-color:#ffffff !important; }
"))),
  
  # ===== Corps =====
  div(
    class = "hud-bg",
    div(class = "hud-title", titlePanel("Observatoire DPE – Nancy & Montpellier")),
    uiOutput("login_panel"),
    
    # Ajout des KPI manquants
    fluidRow(
      column(4,
             div(class = "kpi-box kpi-blue",
                 div(class = "kpi-icon", icon("home")),
                 div(class = "kpi-text",
                     p("Total logements"),
                     h3(textOutput("kpi_total_logements"))
                 )
             )
      ),
      column(4,
             div(class = "kpi-box kpi-red",
                 div(class = "kpi-icon", icon("fire")),
                 div(class = "kpi-text",
                     p("Logements passoires"),
                     h3(textOutput("kpi_passoires"))
                 )
             )
      ),
      column(4,
             div(class = "kpi-box kpi-purple",
                 div(class = "kpi-icon", icon("bolt")),
                 div(class = "kpi-text",
                     p("Conso moyenne"),
                     h3(textOutput("kpi_conso_moyenne"))
                 )
             )
      )
    ),
    
    div(
      class = "hud-main",
      sidebarLayout(
        sidebarPanel(
          width = 3,
          selectInput("ville", "Ville", choices = c("Toutes", sort(unique(df$ville))), selected = "Toutes"),
          selectInput("flag", "Type de logement", choices = c("Tous", sort(unique(df$flag))), selected = "Tous"),
          selectInput("periode", "Période de construction",
                      choices = c("Toutes", levels(df$periode_construction)), selected = "Toutes"),
          selectInput("energie_chauff", "Énergie principale chauffage",
                      choices = c("Toutes", sort(unique(df$type_energie_principale_chauffage))), selected = "Toutes"),
          checkboxGroupInput("dpe_filtre", "Étiquettes DPE", choices = dpe_levels, selected = dpe_levels)
        ),
        mainPanel(
          width = 9,
          tabsetPanel(
            id = "onglets",
            
            # ---- Vue d'ensemble ----
            tabPanel(
              "Vue d'ensemble",
              radioButtons("mode_graph", "Mode des graphiques",
                           choices = c("Interactif" = "plotly", "Statique" = "ggplot"),
                           selected = "plotly", inline = TRUE),
              fluidRow(
                column(6,
                       uiOutput("ui_plot_dpe"),
                       br(),
                       downloadButton("dl_dpe_png", "Exporter DPE (PNG)")
                ),
                column(6,
                       uiOutput("ui_plot_ges"),
                       br(),
                       downloadButton("dl_ges_png", "Exporter GES (PNG)")
                )
              )
            ),
            
            # ---- Comparaisons ----
            tabPanel(
              "Comparaisons détaillées",
              br(),
              tabsetPanel(
                tabPanel(
                  "Conso EP/m² vs période",
                  plotOutput("plot_conso_periode", height = 350),
                  br(),
                  downloadButton("dl_conso_periode_png", "Exporter (PNG)")
                ),
                tabPanel(
                  "Coût chauffage vs DPE",
                  plotOutput("plot_cout_dpe", height = 350),
                  br(),
                  downloadButton("dl_cout_dpe_png", "Exporter (PNG)")
                ),
                tabPanel(
                  "Surface vs coût chauffage",
                  plotOutput("plot_surface_cout", height = 350),
                  br(),
                  downloadButton("dl_surface_cout_png", "Exporter (PNG)")
                ),
                tabPanel(
                  "Régression linéaire",
                  fluidRow(
                    column(4,
                           h4("Choix des variables"),
                           selectInput("reg_x", "Variable explicative (X)", choices = num_vars, selected = default_x),
                           selectInput("reg_y", "Variable à expliquer (Y)", choices = num_vars, selected = default_y),
                           br(), h4("Équation de la droite"),
                           verbatimTextOutput("reg_equation"),
                           br(),
                           downloadButton("dl_regression_png", "Exporter régression (PNG)")
                    ),
                    column(8,
                           plotOutput("plot_regression", height = 350)
                    )
                  )
                )
              )
            ),
            
            # ---- Corrélogramme ----
            tabPanel(
              "Corrélogramme",
              br(),
              plotlyOutput("cor_plotly", height = 600),
              br(),
              downloadButton("dl_cor_png","Exporter corrélogramme (PNG)")
            ),
            
            # ---- Carte ----
            tabPanel(
              "Carte interactive",
              br(),
              leafletOutput("map_dpe", height = "650px"),
              br(),
              downloadButton("dl_map_png", "Exporter la carte (PNG)")
            ),
            
            # ---- Données ----
            tabPanel("Données", br(), DTOutput("table_data"))
          )
        )
      )
    )
  )
)

# -------------------------------------------------------------------
# 3. SERVER
# -------------------------------------------------------------------
server <- function(input, output, session) {
  
  # --------- Auth ----------
  user_logged <- reactiveVal(FALSE)

  output$login_panel <- renderUI({
    if (isTRUE(user_logged())) return(NULL)
    div(
      class = "login-overlay",
      tags$img(src = "https://github.com/mb242/iut_sd2_rshiny_enedis/blob/main/app/www/logo_iut.jpg",    class = "brand-left",  alt = "IUT"),
      tags$img(src = "https://github.com/mb242/iut_sd2_rshiny_enedis/blob/main/app/www/logo_enedis.jpg", class = "brand-right", alt = "Enedis"),
        div(class = "auth-card",
            div(class = "auth-hero",
                span(class = "tag", tagList(icon("bolt"), " OBSERVATOIRE DPE")),
                h1(class = "auth-title",
                   HTML("Accès sécurisé — <span style='color:#93c5fd'>Nancy</span> &amp; <span style='color:#c7d2fe'>Montpellier</span>")
                ),
                p(class = "auth-sub","Analyse des diagnostics, cartographie, indicateurs clés et exports.")
            ),
            div(class = "auth-form",
                h2("Bienvenue asardell"),
                div(class = "note","Veuillez saisir votre identifiant et votre mot de passe."),
                div(class = "login-field",
                    span(class = "login-label", tagList(icon("user"), " Identifiant")),
                    textInput("login_user", label = NULL, placeholder = "ex. votre prenom")
                ),
                div(class = "login-field",
                    span(class = "login-label", tagList(icon("lock"), " Mot de passe")),
                    passwordInput("login_password", label = NULL, placeholder = "••••••••••••••••")
                ),
                div(class = "btn-submit", actionButton("login_btn", "Se connecter")),
                uiOutput("login_feedback"),
                div(class = "auth-foot","Partenariat IUT × Enedis — Accès réservé")
            )
        )
    )
  })
  
  observeEvent(input$login_btn, {
    req(input$login_user, input$login_password)
    valid_user <- "Anthony"; valid_pwd <- "SARDELLITTI"
    if (input$login_user == valid_user && input$login_password == valid_pwd) {
      user_logged(TRUE); output$login_feedback <- renderUI(NULL)
    } else {
      output$login_feedback <- renderUI(tags$p("Identifiants incorrects",
                                               style="color:#f97373; text-align:center;"))
    }
  })
  
  # --------- Données filtrées ----------
  data_filtre <- reactive({
    d <- df
    if (input$ville != "Toutes")   d <- d %>% filter(ville == input$ville)
    if (input$flag != "Tous")      d <- d %>% filter(flag == input$flag)
    if (input$periode != "Toutes" && "periode_construction" %in% names(d))
      d <- d %>% filter(periode_construction == input$periode)
    if (input$energie_chauff != "Toutes")
      d <- d %>% filter(type_energie_principale_chauffage == input$energie_chauff)
    d %>% filter(etiquette_dpe %in% input$dpe_filtre)
  })
  
  # --------- KPI ----------
  output$kpi_total_logements <- renderText({
    format(nrow(data_filtre()), big.mark = " ", scientific = FALSE)
  })
  output$kpi_passoires <- renderText({
    d <- data_filtre(); if (!"etiquette_dpe" %in% names(d)) return("n/a")
    format(sum(d$etiquette_dpe %in% c("F","G"), na.rm = TRUE), big.mark = " ", scientific = FALSE)
  })
  output$kpi_conso_moyenne <- renderText({
    d <- data_filtre(); if (!"conso_5_usages_ef" %in% names(d)) return("n/a")
    paste0(format(round(mean(d$conso_5_usages_ef, na.rm = TRUE), 2), big.mark = " ", scientific = FALSE), " kWh")
  })
  
  # --------- Graphiques réutilisables (ggplot) ----------
  plot_dpe_gg <- reactive({
    d <- data_filtre()
    d$etiquette_dpe <- factor(d$etiquette_dpe, levels = names(dpe_colors))
    niveaux <- levels(d$etiquette_dpe)[levels(d$etiquette_dpe) %in% unique(d$etiquette_dpe)]
    cols_dpe <- dpe_colors[niveaux]
    ggplot(d, aes(x = etiquette_dpe, fill = etiquette_dpe)) +
      geom_bar() +
      geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.3) +
      scale_fill_manual(values = cols_dpe, breaks = names(cols_dpe), drop = TRUE, name = "Étiquette DPE") +
      scale_y_continuous(expand = expansion(mult = c(0, 0.10))) +
      labs(title = "Répartition des logements par étiquette DPE", x = "DPE", y = NULL) +
      theme_minimal() +
      theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
            panel.grid.major.y = element_blank(), panel.grid.minor.y = element_blank())
  })
  plot_ges_gg <- reactive({
    d <- data_filtre()
    d$etiquette_ges <- factor(d$etiquette_ges, levels = names(dpe_colors))
    niveaux <- levels(d$etiquette_ges)[levels(d$etiquette_ges) %in% unique(d$etiquette_ges)]
    cols_ges <- dpe_colors[niveaux]
    ggplot(d, aes(x = etiquette_ges, fill = etiquette_ges)) +
      geom_bar() +
      geom_text(stat = "count", aes(label = after_stat(count)), vjust = -0.3) +
      scale_fill_manual(values = cols_ges, breaks = names(cols_ges), drop = TRUE, name = "Étiquette GES") +
      scale_y_continuous(expand = expansion(mult = c(0, 0.10))) +
      labs(title = "Répartition des logements par étiquette GES", x = "GES", y = NULL) +
      theme_minimal() +
      theme(axis.text.y = element_blank(), axis.ticks.y = element_blank(),
            panel.grid.major.y = element_blank(), panel.grid.minor.y = element_blank())
  })
  
  # ---- Bascule Plotly / ggplot ----
  output$ui_plot_dpe <- renderUI({
    if (input$mode_graph == "plotly") plotlyOutput("plot_dpe_i", height = 300)
    else                             plotOutput ("plot_dpe_s", height = 300)
  })
  output$ui_plot_ges <- renderUI({
    if (input$mode_graph == "plotly") plotlyOutput("plot_ges_i", height = 300)
    else                             plotOutput ("plot_ges_s", height = 300)
  })
  output$plot_dpe_i <- renderPlotly({ ggplotly(plot_dpe_gg()) %>% config(displaylogo = FALSE) })
  output$plot_ges_i <- renderPlotly({ ggplotly(plot_ges_gg()) %>% config(displaylogo = FALSE) })
  output$plot_dpe_s <- renderPlot ({ plot_dpe_gg() })
  output$plot_ges_s <- renderPlot ({ plot_ges_gg() })
  
  # ---- Exports PNG des graphes DPE / GES ----
  output$dl_dpe_png <- downloadHandler(
    filename = function() paste0("dpe_", Sys.Date(), ".png"),
    content  = function(file){
      if (input$mode_graph == "plotly") save_plotly_png(ggplotly(plot_dpe_gg()), file)
      else                              save_ggplot_png(plot_dpe_gg(), file)
    }
  )
  output$dl_ges_png <- downloadHandler(
    filename = function() paste0("ges_", Sys.Date(), ".png"),
    content  = function(file){
      if (input$mode_graph == "plotly") save_plotly_png(ggplotly(plot_ges_gg()), file)
      else                              save_ggplot_png(plot_ges_gg(), file)
    }
  )
  
  # --------- Graphiques Comparaisons (ggplot) ----------
  output$plot_conso_periode <- renderPlot({
    d <- data_filtre(); req("conso_5_usages_par_m2_ep" %in% names(d))
    ggplot(d, aes(x = periode_construction, y = conso_5_usages_par_m2_ep, fill = periode_construction)) +
      geom_boxplot(outlier.colour = "red") +
      coord_cartesian(ylim = c(0, quantile(d$conso_5_usages_par_m2_ep, 0.95, na.rm = TRUE))) +
      labs(title = "Conso 5 usages EP par m² selon la période de construction",
           x = "Période de construction", y = "kWhEP/m².an") +
      theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
  }, bg = "transparent")
  
  output$dl_conso_periode_png <- downloadHandler(
    filename = function() paste0("conso_periode_", Sys.Date(), ".png"),
    content = function(file){
      d <- data_filtre(); req("conso_5_usages_par_m2_ep" %in% names(d))
      p <- ggplot(d, aes(x = periode_construction, y = conso_5_usages_par_m2_ep,
                         fill = periode_construction)) +
        geom_boxplot(outlier.colour = "red") +
        coord_cartesian(ylim = c(0, quantile(d$conso_5_usages_par_m2_ep, 0.95, na.rm = TRUE))) +
        labs(title = "Conso 5 usages EP par m² selon la période de construction",
             x = "Période de construction", y = "kWhEP/m².an") +
        theme_minimal() + theme(axis.text.x = element_text(angle = 45, hjust = 1))
      ggsave(file, plot = p, width = 8, height = 6, dpi = 300)
    }
  )
  
  output$plot_cout_dpe <- renderPlot({
    d <- data_filtre(); req("cout_chauffage" %in% names(d))
    ggplot(d, aes(x = etiquette_dpe, y = cout_chauffage, fill = etiquette_dpe)) +
      geom_boxplot(outlier.colour = "red") +
      coord_cartesian(ylim = c(0, quantile(d$cout_chauffage, 0.95, na.rm = TRUE))) +
      scale_fill_manual(values = dpe_colors, drop = FALSE, name = "Étiquette DPE") +
      labs(title = "Coût de chauffage selon l'étiquette DPE", x = "DPE", y = "€ / an") +
      theme_minimal()
  }, bg = "transparent")
  
  output$dl_cout_dpe_png <- downloadHandler(
    filename = function() paste0("cout_dpe_", Sys.Date(), ".png"),
    content = function(file){
      d <- data_filtre(); req("cout_chauffage" %in% names(d))
      p <- ggplot(d, aes(x = etiquette_dpe, y = cout_chauffage, fill = etiquette_dpe)) +
        geom_boxplot(outlier.colour = "red") +
        coord_cartesian(ylim = c(0, quantile(d$cout_chauffage, 0.95, na.rm = TRUE))) +
        scale_fill_manual(values = dpe_colors, drop = FALSE, name = "Étiquette DPE") +
        labs(title = "Coût de chauffage selon l'étiquette DPE", x = "DPE", y = "€ / an") +
        theme_minimal()
      ggsave(file, plot = p, width = 8, height = 6, dpi = 300)
    }
  )
  
  output$plot_surface_cout <- renderPlot({
    d <- data_filtre(); req(all(c("surface_habitable_logement","cout_chauffage") %in% names(d)))
    d <- d %>% filter(surface_habitable_logement <= quantile(surface_habitable_logement, 0.99, na.rm = TRUE))
    ggplot(d, aes(x = surface_habitable_logement, y = cout_chauffage, color = ville)) +
      geom_point(alpha = 0.5) +
      geom_smooth(method = "lm", se = FALSE, color = "black") +
      labs(title = "Surface habitable vs coût chauffage", x = "Surface habitable (m²)", y = "Coût chauffage (€ / an)") +
      theme_minimal()
  }, bg = "transparent")
  
  output$dl_surface_cout_png <- downloadHandler(
    filename = function() paste0("surface_cout_", Sys.Date(), ".png"),
    content = function(file){
      d <- data_filtre(); req(all(c("surface_habitable_logement","cout_chauffage") %in% names(d)))
      d <- d %>% filter(surface_habitable_logement <= quantile(surface_habitable_logement, 0.99, na.rm = TRUE))
      p <- ggplot(d, aes(x = surface_habitable_logement, y = cout_chauffage, color = ville)) +
        geom_point(alpha = 0.5) +
        geom_smooth(method = "lm", se = FALSE, color = "black") +
        labs(title = "Surface habitable vs coût chauffage",
             x = "Surface habitable (m²)", y = "Coût chauffage (€ / an)") +
        theme_minimal()
      ggsave(file, plot = p, width = 8, height = 6, dpi = 300)
    }
  )
  
  # --------- Régression ----------
  reg_data <- reactive({
    d <- data_filtre(); req(input$reg_x, input$reg_y, input$reg_x %in% names(d), input$reg_y %in% names(d))
    d <- d[, c(input$reg_x, input$reg_y)]; names(d) <- c("x","y")
    d <- d[complete.cases(d), ]; req(nrow(d) > 2); d
  })
  output$plot_regression <- renderPlot({
    d <- reg_data()
    ggplot(d, aes(x = x, y = y)) +
      geom_point(alpha = 0.4) +
      geom_smooth(method = "lm", se = FALSE, color = "#38bdf8") +
      labs(x = input$reg_x, y = input$reg_y,
           title = paste("Régression linéaire :", input$reg_y, "en fonction de", input$reg_x)) +
      theme_minimal()
  }, bg = "transparent")
  output$reg_equation <- renderText({
    d <- reg_data(); mod <- lm(y ~ x, data = d); coefs <- coef(mod)
    paste0("y = ", round(coefs[1], 3),
           ifelse(coefs[2] >= 0, " + ", " - "),
           abs(round(coefs[2], 3)), " * x/n",
           "R² = ", round(summary(mod)$r.squared, 4))
  })
  
  output$dl_regression_png <- downloadHandler(
    filename = function() paste0("regression_", Sys.Date(), ".png"),
    content = function(file){
      d <- reg_data()
      p <- ggplot(d, aes(x = x, y = y)) +
        geom_point(alpha = 0.4) +
        geom_smooth(method = "lm", se = FALSE, color = "#38bdf8") +
        labs(
          x = input$reg_x, y = input$reg_y,
          title = paste("Régression linéaire :", input$reg_y, "en fonction de", input$reg_x)
        ) +
        theme_minimal()
      ggsave(file, plot = p, width = 8, height = 6, dpi = 300)
    }
  )
  
  # --------- Corrélogramme (Plotly) ----------
  cor_mat <- reactive({
    d <- data_filtre() %>% dplyr::select(where(is.numeric))
    req(ncol(d) > 1)
    cor(d, use = "complete.obs")
  })
  output$cor_plotly <- renderPlotly({
    m <- cor_mat()
    plot_ly(
      z = m, type = "heatmap",
      x = colnames(m), y = rownames(m),
      colorscale = list(c(0,"#ef4444"), c(0.5,"#ffffff"), c(1,"#22c55e"))
    ) %>% layout(title = "Corrélogramme (corrélations Pearson)")
  })
  output$dl_cor_png <- downloadHandler(
    filename = function() paste0("correlogramme_", Sys.Date(), ".png"),
    content  = function(file){
      m <- cor_mat()
      p <- plot_ly(
        z = m, type = "heatmap",
        x = colnames(m), y = rownames(m),
        colorscale = list(c(0,"#ef4444"), c(0.5,"#ffffff"), c(1,"#22c55e"))
      )
      save_plotly_png(p, file)
    }
  )
  
  # --------- Carte Leaflet + export ----------
  output$map_dpe <- renderLeaflet({
    d <- data_filtre(); req("lat" %in% names(d), "lon" %in% names(d))
    d <- d %>% dplyr::filter(!is.na(lat), !is.na(lon)); req(nrow(d) > 0)
    
    content <- paste0(
      "<b>Ville :</b> ", d$ville,
      "<br><b>Commune :</b> ", d$nom_commune_ban,
      "<br><b>Surface :</b> ", d$surface_habitable_logement, " m²",
      "<br><b>Conso EP/m² :</b> ", d$conso_5_usages_par_m2_ep,
      "<br><b>DPE :</b> ", d$etiquette_dpe
    )
    
    leaflet(d) %>%
      addProviderTiles("OpenStreetMap") %>%
      fitBounds(min(d$lon, na.rm = TRUE), min(d$lat, na.rm = TRUE),
                max(d$lon, na.rm = TRUE), max(d$lat, na.rm = TRUE)) %>%
      addCircleMarkers(
        lng = ~lon, lat = ~lat, popup = content, radius = 5, color = "black",
        fillColor = ~dpe_colors[etiquette_dpe], stroke = TRUE, weight = 1,
        fillOpacity = 0.7, clusterOptions = markerClusterOptions()
      ) %>%
      addLegend(position = "bottomright",
                colors = dpe_colors[names(dpe_colors) %in% d$etiquette_dpe],
                labels = names(dpe_colors)[names(dpe_colors) %in% d$etiquette_dpe],
                title = "Étiquette DPE")
  })
  # --------- Tableau de données ----------
  output$table_data <- renderDT({
    datatable(
      data_filtre(),
      extensions = "Buttons",
      options = list(
        pageLength = 5, lengthMenu = c(5, 10, 20, 50, 100), scrollX = TRUE,
        dom = "Blfrtip",
        buttons = list(list(extend = "csv", filename = paste0("donnees_dpe_", Sys.Date())),
                       "excel","copy")
      ),
      filter = "top"
    )
  })
}


write.csv(df, "logements_nancy_montpellier.csv.gz")


# -------------------------------------------------------------------
# 4. LANCEMENT
# -------------------------------------------------------------------

shinyApp(ui = ui, server = server)



