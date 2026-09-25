# Shared fixtures for all tests — loaded once before the suite runs.
# Attach sf/dplyr so their S3 methods (filter.sf, vec_slice on sfc, ...)
# are registered before test files manipulate sf objects.

library(sf)
library(dplyr)
library(shiny)

root <- normalizePath(test_path("../.."))

# local = TRUE so the sourced functions close over this environment and can
# see `world`/`backdrop` inside testServer()
for (f in c("sys_deps", "mod_map_panel", "info_card", "overlay",
            "mod_overlay_panel", "theme", "server")) {
  source(file.path(root, "R", paste0(f, ".R")), local = TRUE)
}

world <- readRDS(file.path(root, "data/countries.rds"))
backdrop <- world |> dplyr::filter(NAME != "Antarctica")
