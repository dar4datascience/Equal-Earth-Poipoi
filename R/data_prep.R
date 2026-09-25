# Data preparation for Equal-Earth-Poipoi
# Downloads Natural Earth 110m countries and reads them through DuckDB's
# spatial extension (ST_Read over GDAL's /vsizip/), computing true ellipsoidal
# areas with ST_Area_Spheroid. Used only at build time by
# data-raw/prep_data.R — the app ships the resulting RDS.

ne_url <- "https://naciscdn.org/naturalearth/110m/cultural/ne_110m_admin_0_countries.zip"

download_ne_zip <- function(zip_path, url = ne_url) {
  if (file.exists(zip_path)) {
    cli::cli_inform("Using cached {.file {zip_path}}")
    return(invisible(zip_path))
  }
  dir.create(dirname(zip_path), showWarnings = FALSE, recursive = TRUE)
  cli::cli_inform("Downloading Natural Earth 110m countries...")
  utils::download.file(url, zip_path, mode = "wb", quiet = TRUE)
  invisible(zip_path)
}

read_ne_world <- function(zip_path) {
  zip_abs <- normalizePath(zip_path, mustWork = TRUE)
  shp <- file.path(
    paste0("/vsizip/", zip_abs),
    "ne_110m_admin_0_countries.shp"
  )

  con <- DBI::dbConnect(duckdb::duckdb())
  on.exit(DBI::dbDisconnect(con, shutdown = TRUE), add = TRUE)
  DBI::dbExecute(con, "INSTALL spatial; LOAD spatial;")

  # NOTE: the shapefile stores lon/lat, but EPSG:4326 is authority-defined as
  # lat/lon — always_xy := true tells PROJ to keep x=lon first, otherwise
  # out-of-range "latitudes" silently produce NaN geometries.
  # Area comes from planar area under Equal Earth (EPSG:8857), an equal-area
  # projection — ST_Area_Spheroid() is not used because it assumes lat/lon
  # vertex order and has no always_xy switch.
  # ST_MakeValid repairs self-crossing rings (Russia, Sudan in NE 110m) so
  # downstream sf/s2 operations accept the geometries.
  df <- DBI::dbGetQuery(
    con,
    sprintf(
      "SELECT
         NAME,
         NAME_ES,
         ADMIN,
         ISO_A3,
         ADM0_A3,
         CONTINENT,
         POP_EST,
         ST_Area(
           ST_Transform(geom, 'EPSG:4326', 'EPSG:8857', always_xy := true)
         ) / 1e6 AS area_km2,
         ST_AsText(ST_MakeValid(geom)) AS wkt
       FROM ST_Read('%s')",
      shp
    )
  )

  world <- sf::st_as_sf(df, wkt = "wkt", crs = 4326)
  sf::st_geometry(world) <- "geometry"  # canonical column name

  world |>
    dplyr::mutate(
      name_display = dplyr::coalesce(
        dplyr::na_if(NAME_ES, ""),
        dplyr::na_if(NAME, ""),
        ADMIN
      ),
      country_id = ADM0_A3
    ) |>
    dplyr::arrange(name_display)
}

# Sanity check: DuckDB's Equal Earth area vs sf's own Equal Earth planar
# area — validates the WKT round-trip, axis order, and CRS plumbing.
# (Absolute correctness is anchored in tests/testthat/test-data.R against
# known real-world values; s2 geodesic area is unusable as a cross-check here
# because two NE 110m geometries have self-crossing rings s2 rejects.)
check_areas <- function(world, tolerance = 0.02) {
  eq <- sf::st_transform(world, 8857)
  sf_km2 <- as.numeric(sf::st_area(sf::st_geometry(eq))) / 1e6
  rel_diff <- abs(sf_km2 - world$area_km2) / world$area_km2
  bad <- which(rel_diff > tolerance)
  if (length(bad) > 0) {
    cli::cli_warn(c(
      "!" = "{length(bad)} countr{?y/ies} differ >{tolerance * 100}% between DuckDB and sf Equal Earth areas",
      "i" = "e.g. {world$name_display[bad[1]]}"
    ))
  }
  invisible(rel_diff)
}

prepare_countries <- function(zip_path = "data/ne_110m_admin_0_countries.zip",
                              out_path = "data/countries.rds") {
  download_ne_zip(zip_path)
  world <- read_ne_world(zip_path)

  dupes <- world$country_id[duplicated(world$country_id)]
  if (length(dupes) > 0) {
    cli::cli_abort("Duplicated country_id values: {dupes}")
  }

  check_areas(world)
  saveRDS(world, out_path)
  cli::cli_inform("Wrote {.file {out_path}} ({nrow(world)} countries)")
  invisible(world)
}
