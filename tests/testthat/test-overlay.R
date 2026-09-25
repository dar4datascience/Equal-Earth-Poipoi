# Overlay math (R/overlay.R): shapes centred on a common origin, inflation
# factors against known distortion, and draw order.

test_that("overlay_shapes centres both projections at (0, 0)", {
  s <- overlay_shapes(world[world$country_id == "MEX", ])
  expect_equal(nrow(s), 2)
  expect_equal(levels(s$proj), c("equal_earth", "mercator"))
  for (p in levels(s$proj)) {
    ctr <- s |>
      dplyr::filter(proj == p) |>
      sf::st_geometry() |>
      sf::st_union() |>
      sf::st_centroid() |>
      sf::st_coordinates()
    expect_lt(sqrt(sum(ctr^2)), 1)  # within a metre of the origin
  }
})

test_that("inflation matches known Mercator distortion", {
  infl <- function(id) overlay_shapes(world[world$country_id == id, ])$inflation[1]

  expect_gt(infl("MEX"), 1.1); expect_lt(infl("MEX"), 1.3)
  expect_gt(infl("BRA"), 1.0); expect_lt(infl("BRA"), 1.15)
  expect_gt(infl("RUS"), 4.5); expect_lt(infl("RUS"), 5.3)

  # antimeridian regression: Fiji must not split (huge width) — finite, sane
  expect_true(is.finite(infl("FJI")))
  expect_lt(infl("FJI"), 1.3)
})

test_that("overlay_limits are symmetric and cover every shape", {
  s1 <- overlay_shapes(world[world$country_id == "MEX", ])
  s2 <- overlay_shapes(world[world$country_id == "RUS", ])
  lims <- overlay_limits(list(s1, s2))

  expect_equal(lims$x[1], -lims$x[2])
  expect_equal(lims$y[1], -lims$y[2])

  for (s in list(s1, s2)) {
    bb <- sf::st_bbox(s)
    expect_lt(lims$x[1], bb[["xmin"]])
    expect_gt(lims$x[2], bb[["xmax"]])
    expect_lt(lims$y[1], bb[["ymin"]])
    expect_gt(lims$y[2], bb[["ymax"]])
  }
})

test_that("build_overlay draws Equal Earth on top of Mercator", {
  s <- overlay_shapes(world[world$country_id == "BRA", ])
  p <- build_overlay(s, country_colors[1])

  expect_s3_class(p, "ggplot")
  # layer order: Mercator first, Equal Earth second
  expect_equal(as.character(p$layers[[1]]$data$proj[1]), "mercator")
  expect_equal(as.character(p$layers[[2]]$data$proj[1]), "equal_earth")
})

test_that("inflation_sentence handles near-zero distortion", {
  ecu <- overlay_shapes(world[world$country_id == "ECU", ])
  expect_match(inflation_sentence(ecu), "apenas cambia")
  rus <- overlay_shapes(world[world$country_id == "RUS", ])
  expect_match(inflation_sentence(rus), "aparece .* más grande")
})
