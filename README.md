# Equal-Earth-Poipoi

Dashboard en **R Shiny** que compara la superficie de dos países elegidos por el
usuario bajo dos proyecciones cartográficas:

- **Mercator** (EPSG:3395) — conforme, infla las áreas hacia los polos.
- **Equal Earth** (EPSG:8857, `+proj=eqearth`) — de áreas equivalentes.

Una tercera columna muestra la superficie real de cada país (km²) y la razón
entre ambas ("Brasil es 4,3× más grande que México").

## Arquitectura

```
Build (local / CI)                         Runtime (Posit Connect Cloud)
Natural Earth 110m (.zip)                  data/countries.rds (versionado)
  → DuckDB spatial: ST_Read(/vsizip/)        → app.R lo carga al iniciar
  → ST_Transform(EPSG:8857) + ST_Area        → selectize: país 1 / país 2
  → data/countries.rds                       → ggplot2 + geom_sf → tarjetas bslib
```

DuckDB solo se usa en tiempo de build: la app desplegada no descarga nada ni
carga extensiones.

| Archivo | Propósito |
|---|---|
| `app.R` | UI (bslib) + arranque de la app |
| `R/server.R` | lógica del servidor (`app_server`) |
| `R/mod_map_panel.R` | módulo Shiny del mapa (se usa 2 veces) |
| `R/info_card.R` | tarjeta de comparación (value boxes + razón) |
| `R/theme.R` | tema bslib (preset "shiny", Inter + Space Grotesk, reglas Sass compatibles con modo oscuro) |
| `R/data_prep.R`, `data-raw/prep_data.R` | pipeline DuckDB → `data/countries.rds` |
| `tests/testthat/` | `testServer()`, integridad de datos, E2E `shinytest2` |
| `renv.lock` | entorno reproducible (desarrollo + CI) |
| `manifest.json` | artefacto de despliegue que exige Connect Cloud |

## Puesta en marcha

Requisitos: R ≥ 4.6 y las librerías de sistema de `sf`
(en Ubuntu: `sudo apt install libudunits2-dev libgdal-dev libgeos-dev libproj-dev`).

```r
# 1. Restaurar el entorno exacto (el .Rprofile activa renv automáticamente)
install.packages("renv")
renv::restore()

# 2. (Opcional) regenerar los datos con DuckDB
#    Rscript data-raw/prep_data.R

# 3. Ejecutar la app
shiny::runApp()
```

## Tests

```r
testthat::test_dir("tests/testthat")
```

Tres capas (ver `AGENTS.md`): `testServer()` para la lógica reactiva, pruebas
de integridad sobre `countries.rds`, y un test E2E con `shinytest2` que maneja
la app en Chrome headless. Las capturas de pantalla solo se comparan en local
(se omiten cuando `CI=true`).

## Cambiar dependencias

Siempre regenerar **ambos** archivos y commitearlos juntos:

```r
renv::snapshot()
rsconnect::writeManifest(appPrimaryDoc = "app.R")
```

El CI falla si `renv.lock` o `manifest.json` quedan desactualizados.

## Despliegue en Posit Connect Cloud

**Recomendado — Publicar desde GitHub (sin secretos):**

1. Entrar en [connect.posit.cloud](https://connect.posit.cloud) → **Publish** → **Shiny**.
2. Elegir este repositorio y la rama `main`.
3. Archivo principal: `app.R` → **Publish**.
4. Activar la republicación automática: cada push a `main` redespliega.

**Alternativa — desde GitHub Actions:** el job `deploy` de
`.github/workflows/ci.yml` despliega con `rsconnect::deployApp()` si existen
los secretos `CONNECT_CLOUD_CLIENT_ID`, `CONNECT_CLOUD_CLIENT_SECRET` y
`CONNECT_CLOUD_ACCOUNT`. Sin ellos, el job se omite.

`.rscignore` (y los de `R/` y `data/`) excluyen del bundle los tests, el
pipeline DuckDB y el zip de origen.

## Notas técnicas

- **Orden de ejes:** el shapefile guarda lon/lat, pero EPSG:4326 se define como
  lat/lon. Por eso `ST_Transform(..., always_xy := true)`; sin ello DuckDB
  devuelve `NaN` para la mayoría de los países.
- **Área:** se calcula como área plana en Equal Earth (proyección de áreas
  equivalentes). `ST_Area_Spheroid` no admite `always_xy`.
- **Antártida** se excluye del mapa y del selector: Mercator diverge en los polos.
- **Francia** incluye la Guayana Francesa (así viene en Natural Earth
  `admin_0_countries`), lo que amplía el encuadre de su mapa.
- **thematic** no se usa: la versión 0.1.8 rompe `geom_sf` con ggplot2 4.x a
  partir del segundo render. En su lugar, los mapas se renderizan como PNG
  transparentes con un fondo gris pizarra semitransparente, así se ven bien
  en modo claro y oscuro sin volver a renderizar.

### Entorno sin `sudo`

Si no puedes instalar las librerías de sistema, puedes extraer los `.deb` en
`~/.local/rlibs-root` (`apt download <pkg>` + `dpkg -x`) y fijar su ruta en los
`.so` de `sf`/`units` con `patchelf --set-rpath`. `R/sys_deps.R` apunta
`PROJ_DATA` a `~/.local/rlibs-root/usr/share/proj` si existe; en sistemas
normales no hace nada.

## Datos

[Natural Earth](https://www.naturalearthdata.com/) 1:110m Admin 0 – Countries
(dominio público), descargado desde `naciscdn.org`.
