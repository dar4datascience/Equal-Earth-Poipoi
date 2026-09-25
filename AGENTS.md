You are building and testing a Shiny for R application. Follow these standards
for all work in this repository.

## Skills — invoke before writing code

- **shiny-for-r** — index skill for ALL Shiny work. Read its SKILL.md first,
  then open the linked reference file for each area you touch
  (reactivity, modules, layouts, dynamic-ui, testing, debugging, etc.).
  Do not write code for a covered area without reading its reference.
- **shiny-bslib** — all layouts/components: `page_sidebar()`, `page_navbar()`,
  `layout_columns()`, `card()`, `value_box()`, `accordion()`, `tooltip()`.
- **shiny-bslib-theming** — `bs_theme()`, Bootswatch, dark mode, custom Sass,
  `thematic` for plots, `brand.yml`.
- **modern-r-development-guide** — all R code: native pipe `|>` (never `%>%`),
  dplyr 1.1+ (`join_by()`, `.by`, `pick()`, `across()`, `reframe()`),
  rlang (`{{ }}`, `.data[[]]`, `!!sym()`), tidyverse style.
- **brand-yml** — if the app needs consistent branding across outputs.

## Development rules

- bslib-first UI. Never build `fluidRow()`/`column()` pyramids or hand-rolled
  `div()` markup for things bslib already provides.
- Real nav containers (`navset_tab()`/`nav_panel()`/`page_navbar()`) — never
  fake tabs with `actionButton()` + `conditionalPanel()`.
- Prefer the ecosystem over hand-rolling: DT or reactable for interactive
  tables, plotly for hover/zoom, thematic for plot theming, ExtendedTask +
  promises/mirai for slow work, shinychat for chat UIs.
- Correct reactivity: `reactive()` vs `observeEvent()`/`bindEvent()` chosen
  deliberately; `req()` for validation; `isolate()` for reads that shouldn't
  register dependencies; no `invalidateLater()` polling when an event-based
  pattern works; modules (`moduleServer`) for any repeated UI+server piece.
- Never call outputs or schedule updates imperatively — write the reactive
  graph and let invalidation drive it.

## Testing — three layers, in this order

### Layer 1: Server logic — `testServer()` (always)

- Tests live in `tests/testthat/test-*.R` using testthat.
- Every server function and module gets `testServer()` coverage: drive inputs
  with `session$setInputs()`, assert on reactives and `output$*`.
- `session$setInputs()` flushes the graph; after mutating `reactiveValues()`
  directly, call `session$flushReact()` before asserting.
- Expose internals with `exportTestValues()` — never hidden `textOutput()`s.
- For modules, pass the OUTER function (the one taking `id`) plus `args`.
- NEVER use a browser to verify server-side logic — testServer is milliseconds.

### Layer 2: Dynamic verification — drive a live app

- Launch headless: `shiny::runApp(appDir, port = <random>, launch.browser = FALSE)`
  as a background process, with `test.mode = TRUE` (or
  `options(shiny.testmode = TRUE)`) so `exportTestValues()` and
  `session$getTestSnapshotUrl()` work.
- Drive it with Playwright browser tools (or `chromote` directly): open the
  URL, click through flows, set inputs, take screenshots, read browser console
  and R process logs. Verify what the browser actually renders — not just
  what the code should do.
- `shinytest2::AppDriver$new()` is also acceptable for ad-hoc driving when a
  full browser session isn't needed.

### Layer 3: Automated E2E — `shinytest2` (persist these)

- Convert verified flows into committed tests:
  `tests/testthat/test-shinytest2.R` running `shinytest2::test_app()`, or
  scripts produced by `shinytest2::record_test()`.
- Cover only what a browser can prove: rendered HTML/CSS, JS widget behavior,
  multi-step click-throughs, screenshots (`$expect_screenshot()`).
- Keep E2E tests lean; all logic assertions belong in Layer 1.

## Environment

- R 4.6.x at /usr/local/bin/Rscript. Google Chrome is installed
  (/usr/bin/google-chrome), so chromote/shinytest2 work headless.
- Required packages may be missing — check with
  `rownames(installed.packages())` and install via `pak::pak()` or
  `install.packages()`: shiny, bslib, testthat, shinytest2, chromote
  (plus DT/plotly/thematic/reactlog as the app needs them).

## Workflow per change

1. Write or update `testServer()` tests → run `testthat::test_dir()` /
   `shiny::testApp()`.
2. Launch the app → drive it live (Layer 2) → confirm zero R errors AND zero
   browser console errors.
3. Persist any browser-verified flow as a `shinytest2` test (Layer 3).
4. Debug reactivity puzzles with `reactlog` (`reactlog_enable()` +
   `reactlogShow()`) or real `browser()` breakpoints — never scattered
   `print()` calls.

Done means: testthat suite green, app launches clean, and key interactions
verified in a real browser session.
