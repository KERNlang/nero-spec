# Addon: e2e-sweep

A live, unattended end-to-end and visual-consistency sweep of the whole product: every feature, per persona, driven through the real UI (or API), never judged from code. Collect everything first, report in the morning. Hooks: core step 9 (device-check rows gate DONE for UI specs), `refine` before release/go-live, and on demand.

## When to use

- Before a release or go-live, or on demand ("run the overnight sweep"). Never per small change — single-spec UI work uses its own `Device check:` AC.
- The repo has a UI (web, mobile, desktop) or a public API. API-only → skip the visual audit and i18n screen checks; everything else applies.
- Needs `e2e.md` (below). Missing → draft it with `/spec init` (e2e question) or by hand from the skeleton, then run.

## Config

| `.spec` key | Values | Default |
|---|---|---|
| `e2e.path` | path to the project file | `e2e.md` beside the specs folder: `.claude/e2e.md` for `.claude/specs/…`, `.agents/e2e.md` for `.agents/specs/…` |

`e2e.md` holds everything project-specific; this addon holds the method. The run prompt is: this addon + `e2e.md` + the generated matrix section, in a fresh session at the repo root.

## 1. Setup — verify each, never assume

- **Branches** — every repo named in `e2e.md`: resolve the branch rule (e.g. "newest `release/*-integ`") with `git branch -a` / `git for-each-ref --sort=-committerdate`, pick without asking, **state the chosen branch + sha** at the top of REPORT.md.
- **Environment** — start backing services exactly as `e2e.md` says (containers, migrations, seed). Health check must return its expected status before any scenario. A service dies mid-run → restart, resume the scenario; never skip it silently.
- **App / client** — build and launch per `e2e.md`. Hot-reload suffices for script-only changes; a native rebuild that fails → record it, continue on the last good build, say which.
- **Payments / external side effects** — sandbox or test-store only; never real payment data, real emails to real users, or production endpoints. No sandbox → those rows are `not covered` with the reason.
- **Driver** — confirm the driver in `e2e.md` can tap, type, screenshot and read logs before starting (one smoke step).

## 2. Personas × features matrix

- Every feature in `e2e.md` runs once per persona where it applies; a cell that does not apply is marked `n/a`, not skipped.
- Personas come from `e2e.md` with a **seed recipe** (API calls or script) so each is reproducible: typically anonymous/guest, new/light, heavy (months of realistic data), paid/premium, admin/other roles.
- **Merge / upgrade path persona** whenever the product has one (guest → account, free → paid, device → cloud, v1 data → v2): create data, run the path, verify everything moved, nothing duplicated, no stale tokens or sessions.
- Gated actions: the gate appears from every entry point, including from inside modals and deep links.

## 3. Must-check behaviours (every persona, every feature)

- **No frozen UI, no dead ends** — after every sheet/modal/dialog closes, switch a tab and scroll; every full-screen view has a way out, including after a denied permission and when entered from a deep link or notification.
- **No leaks across personas** — in the UI and directly against the API with each persona's token (list, detail, search, export endpoints). Multiple anonymous users on one device + a registered one. Blocked/removed users see nothing. Run the repo's isolation/authorization test suite if `e2e.md` names one.
- **Offline → sync** — create records offline (or with the network cut), reconnect: each syncs exactly once, no duplicates, no loss; repeat across the merge path.
- **Errors** — zero 5xx in server logs for the whole run; every 4xx is an intended answer (list the unintended ones); no unhandled errors/rejections/red screens in client logs or the browser console.
- **i18n** — every screen in every locale in `e2e.md`: no raw keys, no fallback-language text inside another locale, no truncated labels/pills/buttons; repeat at the largest text size (Dynamic Type / font scale / browser zoom 200%).

## 4. Visual consistency audit (UI only, every screen)

Source of truth = `design_source` in `e2e.md`. Default `code`: the repo's tokens and shared components (paths in `e2e.md`) plus its UI rules file if any.

- **Components** — primary/secondary/destructive buttons, inputs, chips, sheets (handle, backdrop), headers, back/close, empty states, skeletons, toasts use the shared component; same height, radius, font, colours, disabled style everywhere; touch targets ≥ the platform minimum.
- **Type / spacing / colour** — only tokens: no raw sizes, weights, hex values or off-scale spacing; consistent gutters and card padding.
- **Icons** — icon set only (no emoji as icons); same icon for the same meaning.
- **Modes** — dark/light/high contrast where supported; no clipped text, overlap, or layout jump on tab switch or resize.

Each deviation: screenshot path, screen, element, expected token/component (exact name), file path of the offending code.

### Optional: `design_source: figma` (OFF by default)

Only when `e2e.md` sets it and names the file plus a frame map.

- **Token drift** — Figma variables vs code token constants: missing, renamed, value mismatch (one table).
- **Per-screen compare** — only for screens mapped to a frame in `e2e.md`; unmapped screens use the code audit above.
- Each finding says which side is wrong: `fix code` or `update Figma` (code is newer, e.g. a token changed in a merged spec). Never treat Figma as right by default.

## 5. Spec linkage

- **Device checks become rows** — before the run, collect every `Device check:` AC from specs under `specs.path` whose Status is not ARCHIVED/SUPERSEDED/CLOSED:
  ```sh
  <skill dir>/scripts/e2e-matrix.sh [repo-dir] >> <out>/REPORT.md
  ```
  Each row runs as its own scenario under the persona the AC names (else every applicable one).
- **Converge gate** — a UI spec reaches DONE (core step 9) only when its matrix row passes with a screenshot/recording; a failed row keeps it IN PROGRESS and becomes a finding against that spec.
- **Known findings become scenarios** — open `refine` / audit findings (contract mismatches, `CONTRACT-FIELDS`, unmerged consumers, residual risks in `## Refine`) each get an explicit scenario that reproduces them live; report confirmed or not reproduced.

## 6. Working rules

- The orchestrator keeps orchestration; each feature area goes to a fresh-context worker with only: persona tokens/credentials, its scenario rows, the screenshot folder, the must-check list.
- **Collect first, don't fix during the run.** Exception: a bug that blocks further testing → minimal unblock fix, logged in REPORT.md (file, diff summary, why), then continue. Real fixes come after, only when the user asks, per the repo's rules (spec, tests, review).
- Screenshot at every step: `<out>/<persona>/<feature>/NN-step.png` (`<out>` from `e2e.md`, dated).
- REPORT.md is rewritten after each feature (crash-safe: a dead run loses at most one feature).
- Project rules in `e2e.md` (no push, forbidden tools, test constraints) bind every worker.

## 7. Report (`<out>/REPORT.md`, most important first)

1. **Blockers** — freezes, dead ends, data loss, leaks, 5xx, crashes: repro steps, persona, screenshot.
2. **Functional bugs** — grouped by feature.
3. **Visual inconsistencies** — grouped by component type, each with the fix (token/component + file).
4. **i18n** — per locale.
5. **Coverage** — feature × persona table: `pass` / `fail` / `n/a` / `not covered` + reason per not-covered cell; spec device-check rows with PASS/FAIL.
6. **Confidence per area** and what would raise it.

Header: date, chosen branches + shas, build used, unblock fixes applied.

## Driver hints (not mandates)

| Platform | Drive | Screenshot / logs |
|---|---|---|
| iOS simulator | `idb` (tap, type, swipe, ui describe-all) | `xcrun simctl io booted screenshot`; `simctl status_bar`, `simctl ui <dev> appearance dark`, `simctl privacy`, `simctl location` |
| Android emulator | Maestro flows or `adb shell input` | `adb exec-out screencap -p`; `adb logcat` |
| Web | Playwright or browser automation | page screenshots; console + network logs |
| Desktop | platform accessibility automation or Playwright (Electron) | window screenshots; app logs |
| API-only | HTTP client (`curl`, httpie, test client) per persona token | captured request/response per step |

## `e2e.md` skeleton

```markdown
# E2E sweep — <product>
## Setup
- Branches: <repo>: <branch or rule, e.g. newest release/*-integ> · ...
- Start: <commands: services, migrations, seed, app/client launch>
- Health: `<GET /health>` = 200
- Driver: <idb | adb/Maestro | Playwright | HTTP>; reload vs rebuild rule
- Payments: <sandbox/test store; how to grant paid state>
## Personas
1. <name> — <state> — seed: <API calls / script>
## Features
- <area>: <feature>, <feature> (<sub-flows that must be tapped>)
## Must-check extras
- <isolation suite path, offline cases, locales, largest text size>
## Design source
design_source: code — tokens `<path>`, components `<path>`, rules `<file>`   (figma: file + frame map)
## Output
out: `<dir>/e2e-<date>/`
## Project rules
- <no push to main, forbidden tools, test constraints, review policy for later fixes>
```

## Anti-patterns

- Judging a feature from code or unit tests instead of driving it live.
- Fixing as you go — later findings get lost and the report stops being a baseline.
- One persona only; the leak and merge bugs live between personas.
- Screenshots without screen/element/expected token — unactionable.
- Running it per small change instead of the spec's own `Device check:`.
