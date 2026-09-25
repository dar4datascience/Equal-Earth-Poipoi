# Map panel module: one world map card under a given CRS.
# Used twice — Mercator (EPSG:3395) and Equal Earth (EPSG:8857).

country_colors <- c("#1f77b4", "#d62728")  # país 1 azul, país 2 rojo

# Zoom window: bbox of the selected countries in the target CRS, padded.
# Computed per projection, so each map frames the pair in its own geometry.
zoom_limits <- function(selected_t, pad = 0.15) {
  bb <- sf::st_bbox(selected_t)
  dx <- (bb[["xmax"]] - bb[["xmin"]]) * pad
  dy <- (bb[["ymax"]] - bb[["ymin"]]) * pad
  list(
    x = c(bb[["xmin"]] - dx, bb[["xmax"]] + dx),
    y = c(bb[["ymin"]] - dy, bb[["ymax"]] + dy)
  )
}

build_map <- function(backdrop, selected, crs) {
  backdrop_t <- sf::st_transform(backdrop, crs)
  selected_t <- sf::st_transform(selected, crs)
  lims <- zoom_limits(selected_t)

  ggplot2::ggplot() +
    ggplot2::geom_sf(
      data = backdrop_t,
      fill = "grey92",
      color = "white",
      linewidth = 0.15
    ) +
    ggplot2::geom_sf(
      data = selected_t,
      ggplot2::aes(fill = name_display),
      alpha = 0.5,
      color = NA
    ) +
    ggplot2::scale_fill_manual(
      values = stats::setNames(country_colors, selected$name_display)
    ) +
    ggplot2::coord_sf(
      crs = sf::st_crs(crs),
      xlim = lims$x,
      ylim = lims$y,
      expand = FALSE
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(legend.position = "none")
}

map_panel_ui <- function(id, title) {
  ns <- shiny::NS(id)
  bslib::card(
    full_screen = TRUE,
    bslib::card_header(title),
    shiny::plotOutput(ns("map"))
  )
}

map_panel_server <- function(id, backdrop, selected, crs) {
  shiny::moduleServer(id, function(input, output, session) {
    output$map <- shiny::renderPlot(
      {
        sel <- selected()
        shiny::req(nrow(sel) > 0)
        build_map(backdrop, sel, crs)
      },
      alt = shiny::reactive(
        sprintf(
          "Mapa mundial en la proyección %s con %s resaltados",
          crs,
          paste(selected()$name_display, collapse = " y ")
        )
      )
    ) |>
      shiny::bindCache(selected(), cache = "app")
  })
}
