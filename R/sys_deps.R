# Local system-library guard.
# On machines without sudo (like the dev box this was built on), the PROJ/GDAL/
# GEOS .debs are extracted under ~/.local/rlibs-root — see README. Point PROJ at
# its proj.db if present; on normal systems (CI, Connect Cloud) this is a no-op.

use_local_proj_data <- function() {
  local_proj <- file.path(
    Sys.getenv("HOME"),
    ".local/rlibs-root/usr/share/proj"
  )
  if (Sys.getenv("PROJ_DATA") == "" &&
      file.exists(file.path(local_proj, "proj.db"))) {
    Sys.setenv(PROJ_DATA = local_proj)
  }
  invisible()
}

use_local_proj_data()
