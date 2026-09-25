# Regenerate data/countries.rds from Natural Earth via DuckDB spatial.
# Run from the project root:  Rscript data-raw/prep_data.R

source("R/sys_deps.R")
source("data-raw/data_prep.R")

prepare_countries()
