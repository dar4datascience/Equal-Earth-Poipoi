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

info_card_ui <- function() {
  bslib::card(
    bslib::card_header(shiny::textOutput("title_info", inline = TRUE)),
    shiny::uiOutput("info")
  )
}

# Server-side body: two value boxes + ratio sentence.
info_card_body <- function(selected) {
  boxes <- lapply(seq_len(nrow(selected)), function(i) {
    bslib::value_box(
      title = selected$name_display[i],
      value = paste0(format_km2(selected$area_km2[i]), " km²"),
      theme = if (i == 1) "primary" else "danger"
    )
  })

  shiny::tagList(
    # stacked: the info column is only 4/12 wide
    do.call(
      bslib::layout_column_wrap,
      c(list(width = 1, fill = FALSE), boxes)
    ),
    shiny::p(ratio_sentence(selected))
  )
}
