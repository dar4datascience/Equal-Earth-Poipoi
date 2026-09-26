# "Latinoamérica vs EE. UU." section: the 21 Spanish-, Portuguese- and
# French-speaking countries merged into one bloc, compared against the USA.
# Static data — computed once at startup, no inputs involved.

latam_ids <- c(
  "MEX", "GTM", "HND", "SLV", "NIC", "CRI", "PAN",   # México y Centroamérica
  "CUB", "DOM", "HTI", "PRI",                        # Caribe
  "COL", "VEN", "ECU", "PER", "BOL", "BRA", "PRY",   # Sudamérica
  "URY", "ARG", "CHL"
)

# Apparent area (km²) under Mercator (EPSG:3395), the projection of the maps.
mercator_area_km2 <- function(g) {
  as.numeric(sum(sf::st_area(sf::st_transform(g, 3395)))) / 1e6
}

# Two-row sf shaped like `selected` (row 1 = Latinoamérica → blue, row 2 =
# Estados Unidos → red), so build_map() and ratio_sentence() work unchanged.
latam_bloc <- function(world) {
  members <- world |> dplyr::filter(country_id %in% latam_ids)
  usa <- world |> dplyr::filter(country_id == "USA")
  # planar union in Equal Earth: s2 rejects some NE 110m rings
  latam_geom <- members |>
    sf::st_transform(8857) |>
    sf::st_union() |>
    sf::st_transform(4326)

  bloc <- sf::st_sf(
    country_id = c("LATAM", "USA"),
    name_display = c("Latinoamérica", usa$name_display),
    area_km2 = c(sum(members$area_km2), usa$area_km2),
    geometry = c(latam_geom, sf::st_geometry(usa))
  )
  bloc$merc_area_km2 <- vapply(
    seq_len(nrow(bloc)),
    function(i) mercator_area_km2(bloc[i, ]),
    numeric(1)
  )
  bloc
}

# Same bloc with Mercator's apparent areas in place of the real ones.
mercator_apparent <- function(bloc) {
  bloc$area_km2 <- bloc$merc_area_km2
  bloc
}

mercator_ratio_sentence <- function(bloc) {
  a <- bloc$merc_area_km2
  sprintf(
    "En Mercator, %s parece solo %s más grande que %s.",
    bloc$name_display[which.max(a)],
    scales::number(max(a) / min(a), accuracy = 0.1, decimal.mark = ",", suffix = "×"),
    bloc$name_display[which.min(a)]
  )
}

latam_member_names <- function(world) {
  sort(world$name_display[world$country_id %in% latam_ids])
}

# "20,1 M" — millions keep the value short enough for side-by-side boxes
format_mkm2 <- function(x) {
  scales::number(x / 1e6, accuracy = 0.1, decimal.mark = ",", suffix = " M")
}

latam_card_ui <- function(bloc) {
  boxes <- lapply(seq_len(nrow(bloc)), function(i) {
    bslib::value_box(
      title = bloc$name_display[i],
      value = shiny::tagList(
        format_mkm2(bloc$area_km2[i]),
        shiny::span(class = "unit", "km²")
      ),
      theme = if (i == 1) "primary" else "danger"
    )
  })

  bslib::card(
    class = "latam-card",
    bslib::card_header(
      bsicons::bs_icon("rulers"),
      "Superficie total"
    ),
    do.call(bslib::layout_column_wrap, c(list(width = 1 / 2, fill = FALSE), boxes)),
    bslib::layout_column_wrap(
      width = 1 / 2,
      fill = FALSE,
      shiny::div(
        class = "ratio-callout",
        shiny::div(class = "ratio-label", bsicons::bs_icon("globe2"), " Real"),
        shiny::div(class = "ratio-number", ratio_value(bloc)),
        shiny::div(class = "ratio-text", ratio_sentence(bloc))
      ),
      shiny::div(
        class = "ratio-callout",
        shiny::div(class = "ratio-label", bsicons::bs_icon("compass"), " En Mercator"),
        shiny::div(class = "ratio-number", ratio_value(mercator_apparent(bloc))),
        shiny::div(class = "ratio-text", mercator_ratio_sentence(bloc))
      )
    )
  )
}
