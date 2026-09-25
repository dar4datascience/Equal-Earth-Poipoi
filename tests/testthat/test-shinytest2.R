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
  expect_setequal(vals$export$countries, c("México", "Brasil"))

  # selecting another pair updates the exported values
  app$set_inputs(c1 = "JPN", c2 = "FRA", wait_ = TRUE)
  vals <- app$get_values(export = TRUE)
  expect_setequal(vals$export$countries, c("Japón", "Francia"))

  # regression: maps must re-render (not error) after the selection changes
  outs <- app$get_values(output = c("merc-map", "eq-map"))$output
  expect_match(outs[["merc-map"]]$src, "^data:image/png")
  expect_match(outs[["eq-map"]]$src, "^data:image/png")

  # swap button restores a consistent state
  app$click("swap")
  app$wait_for_idle()
  vals <- app$get_values(export = TRUE)
  expect_equal(vals$export$countries, c("Francia", "Japón"))

  app$expect_screenshot()
})
