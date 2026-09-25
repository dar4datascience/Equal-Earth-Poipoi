# Overlay shapes for the "Superposición" section: one country's outline
# under Mercator and Equal Earth, centred on the same point so the size
# difference is exactly Mercator's area inflation.

# Longitude of the country's centroid (planar GEOS — s2 rejects some NE 110m
# rings), used to centre both projections on the country's own meridian.
country_lon0 <- function(country) {
  ctr <- country |>
    sf::st_transform(8857) |>
    sf::st_geometry() |>
    sf::st_union() |>
    sf::st_centroid()
  sf::st_coordinates(sf::st_transform(ctr, 4326))[1]
}

# Two-row sf (proj = mercator | equal_earth) with both outlines shifted so
# their centroids sit at (0, 0). Projections are centred on the country's own
# meridian (+lon_0): it stops antimeridian countries (Rusia, Fiyi) from
# splitting, shifts Mercator sideways only, and is where Equal Earth distorts
# least — the fairest like-for-like comparison.
overlay_shapes <- function(country) {
  stopifnot(nrow(country) == 1)
  lon0 <- country_lon0(country)

  shape_at_origin <- function(crs) {
    g <- sf::st_transform(country, crs)
    ctr <- g |> sf::st_geometry() |> sf::st_union() |> sf::st_centroid()
    sf::st_geometry(g) <- sf::st_geometry(g) - sf::st_coordinates(ctr)[1, ]
    g
  }

  merc <- shape_at_origin(sprintf("+proj=merc +lon_0=%f +datum=WGS84", lon0))
  eq <- shape_at_origin(sprintf("+proj=eqearth +lon_0=%f +datum=WGS84", lon0))
  inflation <- as.numeric(sum(sf::st_area(merc)) / sum(sf::st_area(eq)))

  # Both rows are in shifted Equal Earth metres — arbitrary local units,
  # compared purely against each other.
  geom <- c(sf::st_geometry(eq), sf::st_geometry(merc))
  sf::st_crs(geom) <- 8857

  sf::st_sf(
    name_display = country$name_display,
    country_id = country$country_id,
    proj = factor(c("equal_earth", "mercator")),
    inflation = inflation,
    geometry = geom
  )
}

# Symmetric square limits covering every supplied shape set — for the shared
# (same km per pixel) view. With lims = NULL each panel fits its own country.
overlay_limits <- function(shapes_list, pad = 0.08) {
  bb <- do.call(c, lapply(shapes_list, function(s) {
    sf::st_bbox(s)[c("xmin", "ymin", "xmax", "ymax")]
  }))
  half <- max(abs(bb)) * (1 + pad)
  list(x = c(-half, half), y = c(-half, half))
}

# Nice round scale-bar length (m) ~30% of the panel width.
scale_bar_length <- function(width) {
  target <- width * 0.3 / 1000  # km
  nice <- c(50, 100, 250, 500, 1000, 2500, 5000, 10000)
  nice[which.min(abs(log10(nice) - log10(target)))] * 1000
}

build_overlay <- function(shapes, color, lims = NULL) {
  if (is.null(lims)) {
    # per-panel zoom: square window around the shape's bbox so it doesn't
    # get stretched
    bb <- sf::st_bbox(shapes)
    cx <- mean(c(bb[["xmin"]], bb[["xmax"]]))
    cy <- mean(c(bb[["ymin"]], bb[["ymax"]]))
    span <- max(bb[["xmax"]] - bb[["xmin"]], bb[["ymax"]] - bb[["ymin"]]) / 2 * 1.12
    lims <- list(x = cx + c(-span, span), y = cy + c(-span, span))
  }

  bar <- scale_bar_length(diff(lims$x))
  bar_x <- lims$x[1] + diff(lims$x) * 0.06
  bar_y <- lims$y[1] + diff(lims$y) * 0.08
  bar_df <- data.frame(
    x = bar_x,
    xend = bar_x + bar,
    y = bar_y,
    yend = bar_y,
    label = ifelse(
      bar >= 1e6,
      paste0(bar / 1e6, " mil km"),
      paste0(bar / 1e3, " km")
    )
  )
  transparent <- ggplot2::element_rect(fill = "transparent", colour = NA)

  ggplot2::ggplot() +
    # Mercator first (behind): light fill, dashed outline
    ggplot2::geom_sf(
      data = shapes[shapes$proj == "mercator", ],
      fill = scales::alpha(color, 0.12),
      color = color,
      linetype = "dashed",
      linewidth = 0.6
    ) +
    # Equal Earth last (in front): semi-transparent fill, solid outline
    ggplot2::geom_sf(
      data = shapes[shapes$proj == "equal_earth", ],
      fill = scales::alpha(color, 0.5),
      color = color,
      linewidth = 0.7
    ) +
    ggplot2::geom_segment(
      data = bar_df,
      ggplot2::aes(x = x, y = y, xend = xend, yend = yend),
      color = map_neutral,
      linewidth = 0.8
    ) +
    ggplot2::geom_text(
      data = bar_df,
      ggplot2::aes(x = x + (xend - x) / 2, y = y, label = label),
      color = map_neutral,
      size = 3,
      vjust = -0.6
    ) +
    ggplot2::coord_sf(
      xlim = lims$x,
      ylim = lims$y,
      expand = FALSE,
      datum = sf::st_crs(8857)
    ) +
    ggplot2::theme_void() +
    ggplot2::theme(
      legend.position = "none",
      plot.background = transparent,
      panel.background = transparent
    )
}

inflation_sentence <- function(selected_shapes) {
  name <- selected_shapes$name_display[1]
  f <- selected_shapes$inflation[1]
  if (f < 1.05) {
    sprintf("En Mercator, %s apenas cambia de tamaño.", name)
  } else {
    sprintf(
      "En Mercator, %s aparece %s más grande que su tamaño real.",
      name,
      scales::number(f, accuracy = 0.1, decimal.mark = ",", suffix = "×")
    )
  }
}
