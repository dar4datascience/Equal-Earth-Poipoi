# App theme: bslib "shiny" preset + modern typography + card polish.
# Custom rules use var(--bs-*) custom properties (not Sass variables) so they
# keep working when input_dark_mode() flips data-bs-theme client-side.

app_theme <- function() {
  bslib::bs_theme(
    version = 5,
    preset = "shiny",
    primary = country_colors[1],
    danger = country_colors[2],
    base_font = bslib::font_collection(
      bslib::font_google("Inter", wght = c(400, 500, 600), local = FALSE),
      "system-ui", "-apple-system", "Segoe UI", "sans-serif"
    ),
    heading_font = bslib::font_collection(
      bslib::font_google("Space Grotesk", wght = c(500, 700), local = FALSE),
      "system-ui", "sans-serif"
    ),
    "border-radius" = "0.75rem",
    "card-border-radius" = "1rem",
    "card-border-width" = "0"
  ) |>
    bslib::bs_add_rules("
      /* ---- cards ------------------------------------------------------ */
      .card {
        box-shadow: 0 1px 2px rgba(15, 23, 42, .06),
                    0 8px 24px rgba(15, 23, 42, .06);
        transition: box-shadow .2s ease;
      }
      .card:hover {
        box-shadow: 0 1px 2px rgba(15, 23, 42, .08),
                    0 12px 32px rgba(15, 23, 42, .10);
      }
      [data-bs-theme='dark'] .card,
      [data-bs-theme='dark'] .card:hover {
        box-shadow: 0 0 0 1px var(--bs-border-color-translucent);
      }
      .card-header {
        background: transparent;
        border-bottom: 1px solid var(--bs-border-color-translucent);
        font-family: var(--bs-headings-font-family, inherit);
        font-weight: 600;
        display: flex;
        align-items: center;
        gap: .5rem;
      }
      .card-header .epsg {
        margin-left: auto;
        font-family: var(--bs-font-monospace);
        font-size: .75rem;
        font-weight: 500;
        color: var(--bs-secondary-color);
        background: var(--bs-tertiary-bg);
        padding: .15rem .5rem;
        border-radius: 999px;
      }

      /* ---- navbar title ----------------------------------------------- */
      .app-title {
        font-family: var(--bs-headings-font-family, inherit);
        font-weight: 700;
        font-size: 1.25rem;
        letter-spacing: -.01em;
        display: inline-flex;
        align-items: center;
        gap: .45rem;
      }
      .app-title-accent {
        background: linear-gradient(90deg, #{$primary}, #{$danger});
        -webkit-background-clip: text;
        background-clip: text;
        color: transparent;
      }

      /* ---- sidebar ----------------------------------------------------- */
      .sidebar-intro {
        font-size: .875rem;
        color: var(--bs-secondary-color);
      }
      .country-dot {
        display: inline-block;
        width: .7rem; height: .7rem;
        border-radius: 50%;
        margin-right: .35rem;
        vertical-align: baseline;
      }
      .sidebar-footer {
        font-size: .75rem;
        color: var(--bs-secondary-color);
        border-top: 1px solid var(--bs-border-color-translucent);
        padding-top: .75rem;
      }

      /* ---- value boxes + ratio callout -------------------------------- */
      .card.bslib-value-box .value-box-area .value-box-value {
        font-family: var(--bs-headings-font-family, inherit);
        font-variant-numeric: tabular-nums;
        letter-spacing: -.02em;
        font-size: clamp(1.35rem, 2vw, 1.9rem);
        white-space: nowrap;
      }
      .card.bslib-value-box .value-box-value .unit {
        font-size: .55em;
        font-weight: 500;
        opacity: .85;
        margin-left: .25rem;
      }
      .card.bslib-value-box .value-box-area { padding: 1rem 1.25rem; }
      .ratio-callout {
        text-align: center;
        padding: 1rem .5rem .25rem;
      }
      .ratio-callout .ratio-number {
        font-family: var(--bs-headings-font-family, inherit);
        font-size: clamp(2.5rem, 5vw, 3.75rem);
        font-weight: 700;
        line-height: 1;
        letter-spacing: -.03em;
        background: linear-gradient(90deg, #{$primary}, #{$danger});
        -webkit-background-clip: text;
        background-clip: text;
        color: transparent;
      }
      .ratio-callout .ratio-text {
        margin-top: .5rem;
        color: var(--bs-secondary-color);
      }
      /* the saturated country colors lose contrast on dark surfaces */
      [data-bs-theme='dark'] .ratio-callout .ratio-number,
      [data-bs-theme='dark'] .app-title-accent {
        background-image: linear-gradient(
          90deg, #{lighten($primary, 25%)}, #{lighten($danger, 20%)}
        );
      }

      /* ---- explainer --------------------------------------------------- */
      .explainer p:last-child { margin-bottom: 0; }
    ")
}
