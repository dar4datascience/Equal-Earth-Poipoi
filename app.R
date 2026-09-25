# Equal-Earth-Poipoi — comparación de superficie entre dos países
# bajo Mercator (EPSG:3395) y Equal Earth (EPSG:8857).

library(sf)
library(dplyr)

# local = TRUE: runApp() evaluates app.R in its own environment, so the
# helpers must be defined here to close over `world`/`backdrop` below.
for (f in c("sys_deps", "mod_map_panel", "info_card", "server")) {
  source(file.path("R", paste0(f, ".R")), local = TRUE)
}

world <- readRDS("data/countries.rds")
# Antarctica is excluded from both backdrop and choices: Mercator (EPSG:3395)
# diverges to infinity at the poles, so it can't be framed or compared.
backdrop <- world |> dplyr::filter(NAME != "Antarctica")
country_choices <- stats::setNames(backdrop$country_id, backdrop$name_display)

ui <- bslib::page_sidebar(
  title = "Mercator vs Equal Earth",
  theme = bslib::bs_theme(
    version = 5,
    primary = country_colors[1],
    danger = country_colors[2]
  ),
  sidebar = bslib::sidebar(
    shiny::selectizeInput(
      "c1", "País 1",
      choices = country_choices,
      selected = "MEX"
    ),
    shiny::selectizeInput(
      "c2", "País 2",
      choices = country_choices,
      selected = "BRA"
    ),
    shiny::actionButton(
      "swap", "Intercambiar",
      icon = shiny::icon("arrow-right-arrow-left")
    )
  ),
  bslib::layout_columns(
    col_widths = c(4, 4, 4),
    map_panel_ui("merc", "Mercator (EPSG:3395)"),
    map_panel_ui("eq", "Equal Earth (EPSG:8857)"),
    info_card_ui()
  ),
  bslib::card(
    bslib::card_header("¿Por qué Mercator distorsiona las áreas?"),
    shiny::p(
      "Mercator es una proyección conforme: conserva ángulos y rumbos, lo que",
      "la hizo ideal para la navegación. El precio es que la escala vertical crece",
      "con la secante de la latitud, así que las áreas se inflan hacia los polos —",
      "por eso Groenlandia parece del tamaño de África cuando en realidad es ~14",
      "veces menor."
    ),
    shiny::p(
      "Equal Earth (EPSG:8857) es una proyección de áreas equivalentes: cada",
      "porción del mapa representa la misma superficie real. Al comparar los dos",
      "mapas, un país cercano al ecuador apenas cambia, mientras que uno en",
      "latitudes altas se encoge drásticamente."
    )
  )
)

shiny::shinyApp(ui, app_server)
