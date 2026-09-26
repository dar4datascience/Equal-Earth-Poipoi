# Equal-Earth-Poipoi — comparación de superficie entre dos países
# bajo Mercator (EPSG:3395) y Equal Earth (EPSG:8857).

library(sf)
library(dplyr)

# local = TRUE: runApp() evaluates app.R in its own environment, so the
# helpers must be defined here to close over `world`/`backdrop` below.
for (f in c("sys_deps", "mod_map_panel", "info_card", "overlay",
            "mod_overlay_panel", "latam", "theme", "server")) {
  source(file.path("R", paste0(f, ".R")), local = TRUE)
}

world <- readRDS("data/countries.rds")
# Antarctica is excluded from both backdrop and choices: Mercator (EPSG:3395)
# diverges to infinity at the poles, so it can't be framed or compared.
backdrop <- world |> dplyr::filter(NAME != "Antarctica")
country_choices <- stats::setNames(backdrop$country_id, backdrop$name_display)
latam <- latam_bloc(world)

country_label <- function(text, color) {
  shiny::tagList(
    shiny::span(class = "country-dot", style = paste0("background:", color)),
    text
  )
}

app_sidebar <- bslib::sidebar(
  width = 280,
  shiny::p(
    class = "sidebar-intro",
    "Elige dos países y compara cómo cambia su tamaño aparente entre una",
    "proyección conforme y una de áreas equivalentes."
  ),
  shiny::selectizeInput(
    "c1", country_label("País 1", country_colors[1]),
    choices = country_choices,
    selected = "MEX"
  ),
  shiny::selectizeInput(
    "c2", country_label("País 2", country_colors[2]),
    choices = country_choices,
    selected = "USA"
  ),
  shiny::actionButton(
    "swap", "Intercambiar",
    icon = shiny::icon("arrow-right-arrow-left"),
    class = "btn-outline-primary w-100"
  ),
  shiny::div(
    class = "sidebar-footer mt-auto",
    shiny::div(
      class = "d-flex align-items-center justify-content-between mb-2",
      shiny::span("Modo de color"),
      bslib::input_dark_mode(id = "color_mode")
    ),
    "Datos: Natural Earth 1:110m · áreas calculadas con DuckDB spatial"
  )
)

ui <- bslib::page_navbar(
  # single wrapper: the navbar spreads multiple title children apart
  title = shiny::span(
    class = "app-title",
    bsicons::bs_icon("globe-americas"),
    "Mercator",
    shiny::span(class = "app-title-accent", "vs"),
    "Equal Earth"
  ),
  id = "nav",
  window_title = "Mercator vs Equal Earth",
  # scrolling page: the map row gets an explicit height instead of stretching
  # to the viewport (wide maps in tall cards left lots of empty space)
  fillable = FALSE,
  theme = app_theme(),
  sidebar = app_sidebar,

  bslib::nav_panel(
    "Mapas",
    class = "bslib-page-dashboard",
    icon = bsicons::bs_icon("map"),
    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      height = "460px",
      class = "mb-4",
      map_panel_ui("merc", "Mercator", "EPSG:3395", "compass"),
      map_panel_ui("eq", "Equal Earth", "EPSG:8857", "globe2"),
      info_card_ui()
    ),
    bslib::card(
      class = "explainer",
      bslib::card_header(
        bsicons::bs_icon("lightbulb"),
        "¿Por qué Mercator distorsiona las áreas?"
      ),
      bslib::layout_column_wrap(
        width = 1 / 2,
        fill = FALSE,
        shiny::div(
          shiny::h6(bsicons::bs_icon("compass"), " Mercator — conforme"),
          shiny::p(
            "Conserva ángulos y rumbos, lo que la hizo ideal para la navegación.",
            "El precio es que la escala crece con la secante de la latitud, así",
            "que las áreas se inflan hacia los polos — por eso Groenlandia parece",
            "del tamaño de África cuando en realidad es ~14 veces menor."
          )
        ),
        shiny::div(
          shiny::h6(bsicons::bs_icon("globe2"), " Equal Earth — equivalente"),
          shiny::p(
            "Cada porción del mapa representa la misma superficie real. Al",
            "comparar los dos mapas, un país cercano al ecuador apenas cambia,",
            "mientras que uno en latitudes altas se encoge drásticamente."
          )
        )
      )
    )
  ),

  bslib::nav_panel(
    "Superposición",
    class = "bslib-page-dashboard",
    icon = bsicons::bs_icon("layers"),
    bslib::layout_columns(
      col_widths = 12,
      class = "mb-4",
      bslib::card(
        bslib::card_body(
          class = "d-flex flex-wrap align-items-center gap-4 py-3",
          bslib::input_switch(
            "overlay_fit",
            "Ajustar cada panel a su país",
            value = FALSE
          ),
          shiny::div(
            class = "overlay-legend",
            shiny::span(class = "swatch swatch-dashed"),
            "Mercator",
            shiny::span(class = "swatch swatch-solid"),
            "Equal Earth (al frente)"
          )
        )
      )
    ),
    bslib::layout_columns(
      col_widths = c(6, 6),
      height = "520px",
      overlay_panel_ui("ov1", country_colors[1]),
      overlay_panel_ui("ov2", country_colors[2])
    ),
    bslib::card(
      class = "explainer mt-4",
      bslib::card_header(
        bsicons::bs_icon("lightbulb"),
        "Cómo leer la superposición"
      ),
      shiny::p(
        "Mismo país, dos proyecciones, mismo centro. El contorno punteado es",
        "Mercator; la forma rellena es Equal Earth, que conserva las áreas.",
        "La diferencia de tamaño entre ambos es exactamente la distorsión de",
        "Mercator: con \"escala compartida\" también comparas los dos países",
        "entre sí, y con \"ajustar cada panel\" ves la forma de cada uno",
        "de cerca."
      )
    )
  ),

  bslib::nav_panel(
    "Latinoamérica vs EE. UU.",
    class = "bslib-page-dashboard",
    icon = bsicons::bs_icon("globe-americas"),
    bslib::layout_columns(
      col_widths = c(4, 4, 4),
      height = "460px",
      class = "mb-4",
      map_panel_ui("lat_merc", "Mercator", "EPSG:3395", "compass"),
      map_panel_ui("lat_eq", "Equal Earth", "EPSG:8857", "globe2"),
      latam_card_ui(latam)
    ),
    bslib::card(
      class = "explainer",
      bslib::card_header(
        bsicons::bs_icon("lightbulb"),
        "¿Por qué Mercator casi iguala a los dos bloques?"
      ),
      shiny::p(
        "La mayor parte de Latinoamérica está cerca del ecuador, donde Mercator",
        "apenas distorsiona. Estados Unidos, en cambio, está en latitudes medias",
        "y Alaska llega al Ártico, así que Mercator lo infla mucho más. El",
        "resultado: un bloque que en realidad es más del doble de grande parece",
        "casi del mismo tamaño."
      ),
      shiny::p(
        class = "small text-body-secondary",
        shiny::strong("Países incluidos: "),
        paste0(paste(latam_member_names(world), collapse = ", "), ".")
      )
    )
  )
)

shiny::shinyApp(ui, app_server)
