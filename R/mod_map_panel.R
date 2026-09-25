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

# Slate tone that reads on both light and dark card surfaces; the PNG itself
# is transparent so the card background (and dark mode) shows through.
map_neutral <- "#94a3b8"

build_map <- function(backdrop, selected, crs) {
  backdrop_t <- sf::st_transform(backdrop, crs)
  selected_t <- sf::st_transform(selected, crs)
  lims <- zoom_limits(selected_t)
  palette <- stats::setNames(country_colors, selected$name_display)
  transparent <- ggplot2::element_rect(fill = "transparent", colour = NA)

  ggplot2::ggplot() +
    ggplot2::geom_sf(
      data = backdrop_t,
      fill = scales::alpha(map_neutral, 0.28),
      color = scales::alpha(map_neutral, 0.55),
      linewidth = 0.15
    ) +
    ggplot2::geom_sf(
      data = selected_t,
      ggplot2::aes(fill = name_display, color = name_display),
      alpha = 0.5,
      linewidth = 0.4
    ) +
    ggplot2::scale_fill_manual(values = palette) +
    ggplot2::scale_color_manual(values = palette) +
    ggplot2::coord_sf(
      crs = sf::st_crs(crs),
      xlim = lims$x,
      ylim = lims$y,
      expand = FALSE
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      legend.position = "none",
      # graticule makes each projection's geometry visible: Mercator's
      # parallels spread apart toward the poles, Equal Earth's don't
      panel.grid.major = ggplot2::element_line(
        colour = scales::alpha(map_neutral, 0.3),
        linewidth = 0.2
      ),
      plot.background = transparent,
      panel.background = transparent
    )
}

map_panel_ui <- function(id, title, epsg, icon) {
  ns <- shiny::NS(id)
  bslib::card(
    full_screen = TRUE,
    bslib::card_header(
      bsicons::bs_icon(icon),
      title,
      shiny::span(class = "epsg", epsg)
    ),
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
      ),
      bg = "transparent"
    ) |>
      # crs must be in the key: the app-wide cache is shared by both
      # module instances, and the output id is not part of the key
      shiny::bindCache(selected(), crs, cache = "app")
  })
}
