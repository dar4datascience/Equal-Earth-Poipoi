# Server logic — separate from app.R so testServer() can drive it.
# Uses the app-level globals `world`, `backdrop` and `latam` (defined in app.R,
# and in tests/testthat/setup.R for the test suite).

app_server <- function(input, output, session) {
  # No thematic::thematic_shiny(): thematic 0.1.8 corrupts GeomSf defaults
  # under ggplot2 4.x (every render after the first fails). The maps use
  # explicit colors + theme_void(), so thematic added nothing here.

  selected <- shiny::reactive({
    shiny::req(input$c1, input$c2)
    ids <- c(input$c1, input$c2)
    # keep input order: país 1 first → blue fill
    world |>
      dplyr::filter(country_id %in% ids) |>
      dplyr::slice(match(ids, country_id))
  })

  map_panel_server("merc", backdrop, selected, crs = 3395)
  map_panel_server("eq", backdrop, selected, crs = 8857)

  # "Superposición" section: one overlay per country, computed once and
  # shared between the two panels
  shapes <- shiny::reactive({
    sel <- selected()
    shiny::req(nrow(sel) == 2)
    lapply(seq_len(2), function(i) overlay_shapes(sel[i, ]))
  })

  overlay_lims <- shiny::reactive({
    if (isTRUE(input$overlay_fit)) {
      NULL  # each panel zooms to its own country
    } else {
      overlay_limits(shapes())  # shared scale: same km per pixel
    }
  })

  overlay_panel_server("ov1", shiny::reactive(shapes()[[1]]), country_colors[1], overlay_lims)
  overlay_panel_server("ov2", shiny::reactive(shapes()[[2]]), country_colors[2], overlay_lims)

  # "Latinoamérica vs EE. UU." section: same overlay module, one panel per
  # bloc. The bloc is static; the reactive only defers the projection work
  # until the tab is first shown.
  latam_shapes <- shiny::reactive(
    lapply(seq_len(nrow(latam)), function(i) overlay_shapes(latam[i, ]))
  )

  latam_lims <- shiny::reactive({
    if (isTRUE(input$latam_fit)) NULL else overlay_limits(latam_shapes())
  })

  overlay_panel_server("lat_ov1", shiny::reactive(latam_shapes()[[1]]), country_colors[1], latam_lims)
  overlay_panel_server("lat_ov2", shiny::reactive(latam_shapes()[[2]]), country_colors[2], latam_lims)

  output$title_info <- shiny::renderText({
    sel <- selected()
    sprintf(
      "Comparación de superficie: %s vs %s",
      sel$name_display[1], sel$name_display[2]
    )
  })

  output$info <- shiny::renderUI(info_card_body(selected()))

  shiny::observeEvent(input$swap, {
    shiny::updateSelectizeInput(session, "c1", selected = input$c2)
    shiny::updateSelectizeInput(session, "c2", selected = input$c1)
  })

  shiny::exportTestValues(
    countries = selected()$name_display,
    areas_km2 = round(selected()$area_km2),
    ratio = ratio_sentence(selected()),
    inflation = vapply(
      shapes(),
      function(s) round(s$inflation[1], 2),
      numeric(1)
    ),
    latam_ratio = ratio_sentence(latam),
    latam_inflation = vapply(
      latam_shapes(),
      function(s) round(s$inflation[1], 2),
      numeric(1)
    )
  )
}
