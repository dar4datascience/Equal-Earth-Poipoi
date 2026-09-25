# Overlay panel module: one country's Mercator + Equal Earth outlines
# superposed, with its Mercator inflation callout. Used twice (one per
# selected country) — the two instances share the limits reactive.

overlay_panel_ui <- function(id, color) {
  ns <- shiny::NS(id)
  bslib::card(
    full_screen = TRUE,
    bslib::card_header(
      shiny::span(class = "country-dot", style = paste0("background:", color)),
      shiny::textOutput(ns("name"), inline = TRUE)
    ),
    shiny::plotOutput(ns("plot"), fill = TRUE),
    bslib::card_body(
      class = "pt-1",
      shiny::uiOutput(ns("inflate"))
    )
  )
}

overlay_panel_server <- function(id, shapes, color, lims) {
  shiny::moduleServer(id, function(input, output, session) {
    output$name <- shiny::renderText(shapes()$name_display[1])
    output$plot <- shiny::renderPlot(
      build_overlay(shapes(), color, lims()),
      alt = shiny::reactive(sprintf(
        "Superposición de %s: contorno punteado en Mercator sobre la forma real en Equal Earth",
        shapes()$name_display[1]
      )),
      bg = "transparent"
    ) |>
      # key on the country's id + limits (they decide the image), not the
      # shapes object itself
      shiny::bindCache(shapes()$country_id[1], lims(), cache = "app")
    output$inflate <- shiny::renderUI(
      shiny::div(
        class = "ratio-callout",
        shiny::div(
          class = "ratio-number",
          style = paste0("color:", color, "; background: none; -webkit-text-fill-color:", color),
          if (shapes()$inflation[1] >= 1.05) {
            scales::number(
              shapes()$inflation[1],
              accuracy = 0.1, decimal.mark = ",", suffix = "×"
            )
          } else {
            "≈1×"
          }
        ),
        shiny::div(class = "ratio-text", inflation_sentence(shapes()))
      )
    )
  })
}
