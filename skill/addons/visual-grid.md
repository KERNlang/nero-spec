# Addon: visual-grid

Hook: core step 4 (UI changes), step 9 (converge).

Replaces how core's per-AC `Device check:` is met for UI ACs while loaded: the check is the grid.

## When to use

Any change a user sees: layout, styling, components, map or canvas UI. One grid per UI change, scoped to the
surfaces it touches. Not for backend-only work.

## What it adds to the spec

- One `Visual grid:` line in the Verification or Completion section: URL, screens folder, result.
- Grid: desktop 1440×900 and mobile 390×844, each light and dark (`prefers-color-scheme` emulated).
- Each UI AC keeps one line `Device check: visual grid → <screens folder>`, so `e2e-sweep` (`scripts/e2e-matrix.sh`)
  still collects it.
- Tool: `node <skill-dir>/scripts/shotgrid.mjs <url> <spec-dir>/screens/<slice> [--wait <css-selector>]`.
  One headless browser and one page; viewport and color scheme switch in place. Measured on a Nuxt web app:
  ~800 MB peak for ~15 s, freed on exit. Needs Node and `playwright-core` with its headless shell;
  `PW_CORE` / `PW_EXE` override where they are found. URL: https, or http on localhost.
- Hard gate: a UI AC is not met without its grid, and the agent has looked at all four shots.

## Required patterns

- Prefer a deployed preview URL over a local dev server; run one grid at a time.
- Canvas-heavy pages: pass `--wait` with a selector that appears once tiles are drawn.
- Link the four shots in the slice review.

## Anti-patterns

- Claiming a UI fix from code or tests alone.
- Starting several browsers or dev servers in parallel on a laptop.
- Screenshots of a stale local server while the preview runs a different build.
