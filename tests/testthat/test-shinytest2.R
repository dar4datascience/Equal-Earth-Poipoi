# Layer 3: end-to-end with shinytest2 — covers what only a browser can prove
# (rendered cards, selectize widgets, screenshot). Server-logic assertions
# live in test-server.R.

test_that("app launches, selects countries, and swaps", {
  skip_if_not_installed("shinytest2")
  # AppDriver skips itself on CRAN; keep it runnable locally/CI
  withr::local_envvar(NOT_CRAN = "true")
  skip_if(Sys.which("google-chrome") == "" &&
          Sys.which("chromium") == "",
          "No headless browser available")

  app <- shinytest2::AppDriver$new(
    test_path("../.."),
    name = "equal-earth",
    variant = shinytest2::platform_variant(),
    width = 1400,
    height = 900,
    load_timeout = 30 * 1000,
    shiny_args = list(test.mode = TRUE)
  )
  on.exit(app$stop())
  app$wait_for_idle()

  # default pair is rendered
  vals <- app$get_values(export = TRUE)
  expect_setequal(vals$export$countries, c("México", "Estados Unidos"))

  # selecting another pair updates the exported values
  app$set_inputs(c1 = "JPN", c2 = "FRA", wait_ = TRUE)
  vals <- app$get_values(export = TRUE)
  expect_setequal(vals$export$countries, c("Japón", "Francia"))

  # regression: maps must re-render (not error) after the selection changes
  outs <- app$get_values(output = c("merc-map", "eq-map"))$output
  expect_match(outs[["merc-map"]]$src, "^data:image/png")
  expect_match(outs[["eq-map"]]$src, "^data:image/png")
  # regression: the shared plot cache must not serve one projection's
  # image to the other panel
  expect_false(identical(outs[["merc-map"]]$src, outs[["eq-map"]]$src))

  # swap button restores a consistent state
  app$click("swap")
  app$wait_for_idle()
  vals <- app$get_values(export = TRUE)
  expect_equal(vals$export$countries, c("Francia", "Japón"))

  # ---- Superposición tab -------------------------------------------------
  app$set_inputs(nav = "Superposición")
  app$wait_for_idle()

  vals <- app$get_values(export = TRUE)
  expect_length(vals$export$inflation, 2)

  ov <- app$get_values(output = c("ov1-plot", "ov2-plot"))$output
  expect_match(ov[["ov1-plot"]]$src, "^data:image/png")
  expect_match(ov[["ov2-plot"]]$src, "^data:image/png")
  # two different countries → different overlays
  expect_false(identical(ov[["ov1-plot"]]$src, ov[["ov2-plot"]]$src))

  # toggling per-panel zoom re-renders the plots
  before <- ov[["ov1-plot"]]$src
  app$set_inputs(overlay_fit = TRUE)
  app$wait_for_idle()
  ov <- app$get_values(output = c("ov1-plot", "ov2-plot"))$output
  expect_false(identical(ov[["ov1-plot"]]$src, before))
  app$set_inputs(overlay_fit = FALSE)

  # ---- Latinoamérica vs EE. UU. tab ----------------------------------------
  app$set_inputs(nav = "Latinoamérica vs EE. UU.")
  app$wait_for_idle()

  lat <- app$get_values(output = c("lat_ov1-plot", "lat_ov2-plot"))$output
  expect_match(lat[["lat_ov1-plot"]]$src, "^data:image/png")
  expect_match(lat[["lat_ov2-plot"]]$src, "^data:image/png")
  expect_false(identical(lat[["lat_ov1-plot"]]$src, lat[["lat_ov2-plot"]]$src))
  expect_length(app$get_values(export = TRUE)$export$latam_inflation, 2)

  # per-bloc zoom re-renders the overlays
  before <- lat[["lat_ov1-plot"]]$src
  app$set_inputs(latam_fit = TRUE)
  app$wait_for_idle()
  after <- app$get_values(output = "lat_ov1-plot")$output[["lat_ov1-plot"]]$src
  expect_false(identical(after, before))
  app$set_inputs(latam_fit = FALSE)

  # the static card renders both ratios, independent of the sidebar pair
  card <- app$get_text(".latam-card")
  expect_match(card, "2,1×")
  expect_match(card, "1,1×")
  expect_match(app$get_values(export = TRUE)$export$latam_ratio, "Latinoamérica")

  # back to the first tab for the snapshot
  app$set_inputs(nav = "Mapas")
  # input_dark_mode() follows the browser's prefers-color-scheme, which varies
  # between headless runs — pin dark mode so the screenshot is reproducible
  app$run_js("document.documentElement.setAttribute('data-bs-theme', 'dark');")
  app$wait_for_idle()

  # pixel snapshots depend on local fonts/rendering — keep them local-only
  if (!isTRUE(as.logical(Sys.getenv("CI", "false")))) {
    app$expect_screenshot()
  }
})
