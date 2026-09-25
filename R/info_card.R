# Info card: name, surface area and size ratio for the two selected
# countries — the third column of the dashboard.

format_km2 <- function(x) {
  scales::number(x, accuracy = 1, big.mark = ".", decimal.mark = ",")
}

# "Brasil es 4,3× más grande que México" (first row = país 1)
ratio_sentence <- function(selected) {
  a1 <- selected$area_km2[1]
  a2 <- selected$area_km2[2]
  n1 <- selected$name_display[1]
  n2 <- selected$name_display[2]

  ratio <- max(a1, a2) / min(a1, a2)
  bigger <- if (a2 >= a1) n2 else n1
  smaller <- if (a2 >= a1) n1 else n2

  if (ratio < 1.05) {
    sprintf("%s y %s tienen una superficie prácticamente igual.", n1, n2)
  } else {
    sprintf(
      "%s es %s× más grande que %s.",
      bigger,
      scales::number(ratio, accuracy = 0.1, decimal.mark = ","),
      smaller
    )
  }
}

# "4,3×" — headline number for the ratio callout
ratio_value <- function(selected) {
  a <- selected$area_km2[1:2]
  scales::number(max(a) / min(a), accuracy = 0.1, decimal.mark = ",", suffix = "×")
}

info_card_ui <- function() {
  bslib::card(
    bslib::card_header(
      bsicons::bs_icon("rulers"),
      shiny::textOutput("title_info", inline = TRUE)
    ),
    shiny::uiOutput("info")
  )
}

# Server-side body: two value boxes + ratio callout.
info_card_body <- function(selected) {
  boxes <- lapply(seq_len(nrow(selected)), function(i) {
    bslib::value_box(
      title = selected$name_display[i],
      value = shiny::tagList(
        format_km2(selected$area_km2[i]),
        shiny::span(class = "unit", "km²")
      ),
      showcase = bsicons::bs_icon("geo-alt-fill"),
      showcase_layout = "top right",
      theme = if (i == 1) "primary" else "danger"
    )
  })

  shiny::tagList(
    # stacked: the info column is only 4/12 wide
    do.call(
      bslib::layout_column_wrap,
      c(list(width = 1, fill = FALSE), boxes)
    ),
    shiny::div(
      class = "ratio-callout",
      shiny::div(class = "ratio-number", ratio_value(selected)),
      shiny::div(class = "ratio-text", ratio_sentence(selected))
    )
  )
}
