# Layer 1b: integrity of the bundled data asset produced by
# data-raw/prep_data.R (DuckDB spatial pipeline).

test_that("countries.rds has the expected shape and columns", {
  expect_s3_class(world, "sf")
  expect_equal(nrow(world), 177)
  expect_true(all(
    c("NAME", "NAME_ES", "ISO_A3", "country_id", "name_display",
      "area_km2", "geometry") %in% names(world)
  ))
  expect_equal(sf::st_crs(world)$epsg, 4326)
})

test_that("country ids are unique and display names complete", {
  expect_false(any(duplicated(world$country_id)))
  expect_false(any(is.na(world$name_display) | world$name_display == ""))
})

test_that("areas are sane against known real-world values", {
  area_of <- function(id) world$area_km2[world$ISO_A3 == id]

  expect_gt(area_of("MEX"), 1.85e6)
  expect_lt(area_of("MEX"), 2.05e6)

  expect_gt(area_of("BRA"), 8.3e6)
  expect_lt(area_of("BRA"), 8.7e6)

  # every country has a positive finite area
  expect_true(all(is.finite(world$area_km2) & world$area_km2 > 0))
})

test_that("Spanish display names cover the default selection", {
  expect_equal(world$name_display[world$ISO_A3 == "MEX"], "México")
  expect_equal(world$name_display[world$ISO_A3 == "BRA"], "Brasil")
})
