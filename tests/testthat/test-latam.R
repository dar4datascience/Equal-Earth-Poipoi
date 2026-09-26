# Latinoamérica vs EE. UU. (R/latam.R): bloc construction, real vs
# Mercator-apparent ratios, and the static info card.

test_that("every Latin American id exists in the data", {
  expect_length(latam_ids, 21)
  expect_true(all(latam_ids %in% world$country_id))
  expect_false("USA" %in% latam_ids)
})

test_that("latam_bloc is a two-row sf: Latinoamérica first, then USA", {
  expect_s3_class(latam, "sf")
  expect_equal(latam$country_id, c("LATAM", "USA"))
  expect_equal(latam$name_display, c("Latinoamérica", "Estados Unidos"))
  expect_true(all(sf::st_is_valid(latam)))
  expect_equal(sf::st_crs(latam)$epsg, 4326)
})

test_that("bloc area is the sum of its member countries", {
  members <- world$area_km2[world$country_id %in% latam_ids]
  expect_equal(latam$area_km2[1], sum(members))
  expect_equal(latam$area_km2[2], world$area_km2[world$country_id == "USA"])
})

test_that("Mercator shrinks the real ~2x gap to almost nothing", {
  real <- latam$area_km2[1] / latam$area_km2[2]
  merc <- latam$merc_area_km2[1] / latam$merc_area_km2[2]
  expect_gt(real, 2.0); expect_lt(real, 2.2)
  expect_gt(merc, 1.0); expect_lt(merc, 1.2)

  # Mercator inflates both, but the USA (Alaska) far more
  inflation <- latam$merc_area_km2 / latam$area_km2
  expect_true(all(inflation > 1))
  expect_gt(inflation[2], inflation[1])
})

test_that("sentences name the bigger bloc first", {
  expect_match(ratio_sentence(latam), "Latinoamérica es 2,1× más grande que Estados Unidos")
  expect_match(mercator_ratio_sentence(latam), "En Mercator, Latinoamérica parece solo 1,1×")
})

test_that("latam_card_ui shows both areas and both ratios", {
  html <- as.character(latam_card_ui(latam))
  expect_match(html, "Latinoamérica")
  expect_match(html, "Estados Unidos")
  expect_match(html, "km²")
  expect_match(html, "2,1×")
  expect_match(html, "1,1×")
})

test_that("member list covers the 21 countries", {
  expect_length(latam_member_names(world), 21)
  expect_true(all(c("México", "Brasil", "Haití") %in% latam_member_names(world)))
})
