# Addon: visual-grid

Hook: core step 4 (UI changes), step 9 (converge).

## When to use

Any change a user sees: layout, styling, components, map or canvas UI. One grid per UI change, scoped to the
surfaces it touches. Not for backend-only work.

## What it adds to the spec

- One `Visual grid:` line in the Verification or Completion section: URL, screens folder, result.
- Grid: desktop 1440×900 and mobile 390×844, each light and dark (`prefers-color-scheme` emulated).
- Tool: `node scripts/shotgrid.mjs <https-url> <spec-dir>/screens/<slice> [--wait <css-selector>]`.
  One headless browser and one page; viewport and color scheme switch in place. Measured on a Nuxt web app:
  ~800 MB peak for ~15 s, freed on exit. Needs Node and `playwright-core` with its headless shell.
- Converge: a UI AC is met only with its grid, and the agent has looked at all four shots.

## Required patterns

- Prefer a deployed preview URL over a local dev server; run one grid at a time.
- Canvas-heavy pages: pass `--wait` with a selector that appears once tiles are drawn.
- Link the four shots in the slice review.

## Anti-patterns

- Claiming a UI fix from code or tests alone.
- Starting several browsers or dev servers in parallel on a laptop.
- Screenshots of a stale local server while the preview runs a different build.
