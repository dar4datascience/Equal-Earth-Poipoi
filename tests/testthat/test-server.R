# Layer 1: server logic via testServer() — no browser needed.
# app_server() reads the globals `world`/`backdrop`, which setup.R provides.

test_that("selected() returns the two countries in input order", {
  testServer(app_server, {
    session$setInputs(c1 = "MEX", c2 = "BRA")
    expect_equal(nrow(selected()), 2)
    expect_equal(selected()$country_id, c("MEX", "BRA"))

    session$setInputs(c1 = "JPN", c2 = "FRA")
    expect_equal(selected()$country_id, c("JPN", "FRA"))
  })
})

test_that("info title and ratio sentence reflect the selection", {
  testServer(app_server, {
    session$setInputs(c1 = "MEX", c2 = "BRA")
    expect_match(output$title_info, "México vs Brasil")
    expect_match(output$info$html, "más grande")
    expect_match(output$info$html, "km²")
  })
})

test_that("ratio sentence handles equal-ish and inverted pairs", {
  testServer(app_server, {
    session$setInputs(c1 = "BRA", c2 = "MEX")
    # país 1 is now the bigger one — sentence still names it first correctly
    expect_match(ratio_sentence(selected()), "Brasil es .* más grande que México")
  })
})

test_that("map_panel module renders a PNG under both projections", {
  sel <- shiny::reactive(
    world |> dplyr::filter(country_id %in% c("MEX", "BRA"))
  )
  for (crs in c(3395, 8857)) {
    testServer(
      map_panel_server,
      args = list(backdrop = backdrop, selected = sel, crs = crs),
      {
        # renderPlot output resolves to a result list: embedded PNG + alt text
        expect_match(output$map$src, "^data:image/png")
        expect_match(output$map$alt, "resaltados")
      }
    )
  }
})

test_that("build_map carries the spec's palette and no axes", {
  sel <- world |> dplyr::filter(country_id %in% c("MEX", "BRA"))
  p <- build_map(backdrop, sel, crs = 8857)

  expect_s3_class(p, "ggplot")
  # theme_void → axis text/ticks are element_blank
  expect_s3_class(p$theme$axis.text, "element_blank")
  # país 1 → blue, país 2 → red in the country layer's resolved fills
  fills <- unique(substr(ggplot2::ggplot_build(p)$data[[2]]$fill, 1, 7))
  expect_setequal(fills, country_colors)
})
