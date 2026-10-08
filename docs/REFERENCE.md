# Nero Spec — Reference

Everything the [README](../README.md) leaves out: layout, presets, addons, config, lifecycle, drift checks, install details.

## Layout

- **core** (`skill/core.md`) — the flow every spec follows: spec → refine → build → review → converge/done. Goal: nothing changes after review.
- **addons** (`skill/addons/*.md`) — one concern each, self-contained; plug into a named core step.
- **presets** (`skill/presets/*.md`) — default addons + settings + a short constitution (commits, review tooling, risk notes).
- **init** (`skill/init.md`) — `/spec init` asks the machine questions once, then the repo questions, and writes the config.
- **machine vs repo** — the machine file says what this computer has (rules file, Agon, mutation tooling); the repo config says what this repo allows. Works on any machine, with or without Agon, without anyone's personal files.

```
skill/
  SKILL.md          router: resolve config → load core + preset + addons → run
  core.md           shared flow
  init.md           /spec init
  presets/          personal, team, enterprise, operator-reviewed
  addons/           depth-light, tier-1..4, refine, contract-discovery, release-contract,
                    success-metrics, user-stories, criteria-test-map,
                    agon-oracle, jira-ticket, issue-link, drift-guard, e2e-sweep, visual-grid,
                    ticket-interpretation, changed-things, completion-conditions,
                    contested-decision-scan (experimental)
  scripts/
    spec-check.sh       advisory spec health scan (drift, citations, status, pointers, repeated fixes)
    spec-check-lib.sh   parsing helpers sourced by spec-check.sh
    spec-check-contract.sh  contract checks sourced by spec-check.sh
    spec-check-policy.sh    company policy load + checks sourced by spec-check.sh
    spec-check-policy-local.sh  optional policy_paths lookup (not copied into vendored repos)
    list-skills.sh      read-only scan of the repo's own agent skills with a suggested step (used by /spec init 2e)
    pre-commit-spec-check.sh  optional advisory git hook (staged specs + specs whose Changes are staged)
    spec-drift.sh       alias for spec-check.sh
    test-spec-check.sh  fixture tests for spec-check.sh
    test-spec-hardening-checker.sh  selectable checker regressions
    test-spec-hardening-installer.sh  selectable installer regressions
    test-spec-path-safety.sh  configured spec-path safety regressions
    test-spec-review-security.sh  hostile filename and fixture temp-failure regressions
    test-spec-review-compat.sh  review compatibility regressions
    e2e-matrix.sh       collects `Device check:` ACs into a matrix section for an e2e-sweep report
    test-e2e-matrix.sh  fixture tests for e2e-matrix.sh
    shotgrid.mjs        4-shot visual grid (desktop/mobile × light/dark) for visual-grid
    test-shotgrid.sh    argument tests for shotgrid.mjs (no browser)
    test-spec-check-nogit.sh  non-git target, dir-hash, OPEN-CAP, REFINE-STEPS fixtures
    test-spec-check-stacks.sh  stack fixtures sourced by test-spec-check.sh
    test-spec-check-policy.sh  company policy fixtures
    test-spec-check-pr-title.sh  --pr-title fixtures
    test-list-skills.sh  fixture tests for list-skills.sh
    test-install-copy-mode.sh  installer copy-mode regression
```

## Presets

| Preset | Default addons | agon | specs.path |
|---|---|---|---|
| personal | depth-light, refine, drift-guard, criteria-test-map (goal/conquer + forced triggers), agon-oracle | full | `.claude/specs/{slug}/spec.md` |
| team | tier-1, tier-2, refine, drift-guard, contract-discovery, criteria-test-map, success-metrics (tier 2), issue-link, agon-oracle | full | `.claude/specs/{slug}/spec.md` |
| enterprise | jira-ticket, tier-1..4, refine, drift-guard, contract-discovery, success-metrics, criteria-test-map, user-stories (tier 4), e2e-sweep (release) | ask (= off until answered) | `.agents/specs/{TICKET}-{slug}/spec.md` |
| operator-reviewed | depth-light, refine, drift-guard, criteria-test-map, visual-grid, ticket-interpretation, changed-things, completion-conditions | ask (= off until granted) | `.claude/specs/{slug}/spec.md` |

On demand, regardless of preset: `contract-discovery` when a boundary is crossed, `release-contract` for client↔backend releases, higher tiers (team/enterprise) when a trigger demands them, `criteria-test-map` for auth/guest/payment/persistence/deletion/privacy. A `-name` in `.spec` blocks that.

## Add-ons

| Add-on | Purpose |
|---|---|
| `refine` | After drafting, on resume, before release: spec-check, contract compare (producer + every consumer, file:line both sides), re-verify VERIFIED/ASSUMED, ≤ 6 blind-spot questions → ACs, critique by risk (Agon or fresh subagent), max 2 rounds, ≤ 6-line `## Refine` block |
| `drift-guard` | `## Changes` as the drift anchor; STALE / XREPO / REPEAT-FIX; record or living specs |
| `contract-discovery` / `release-contract` | Both sides of a boundary; old clients, compat window, deploy order |
| `criteria-test-map` | AC ↔ test both ways, mutation-proven |
| `e2e-sweep` | Before release / overnight: live personas × features sweep, leak/offline/error/i18n checks, visual audit vs code tokens (Figma optional), crash-safe REPORT.md; spec `Device check:` ACs become rows (`scripts/e2e-matrix.sh`) and gate DONE. Project specifics in `e2e.md` (`.spec` `e2e.path`). Suggested for personal/team, on for enterprise |
| `visual-grid` | One low-RAM screenshot grid (desktop + mobile × light + dark) per UI change via `scripts/shotgrid.mjs`; hard gate replacing `Device check:` for UI ACs; on in `operator-reviewed` |
| `ticket-interpretation` | Replaces core `## Intent`: Purpose and authority + Ticket interpretation (Accepted/Proposed/Open); ticket re-read before approval and PR. On in `operator-reviewed` |
| `changed-things` | Replaces `Callers:` / `Real usage:`: Changed things table with contract change, used-by count and evidence, plus Precedent per option. On in `operator-reviewed` |
| `completion-conditions` | Replaces `Done when` / As-built delta: `## Completion conditions`, per-AC met / not met, `## What was not done`. On in `operator-reviewed` |
| `contested-decision-scan` | Experimental, off by default. Before drafting: finds choices with two defensible readings, turns each reading's breakage into a test, settles only on consumer evidence, else ships the less restrictive reading |
| `depth-light` / `tier-1..4` | Depth: Surgical (≤ ~60 lines) or Full (≤ ~300, then split) |
| `success-metrics`, `user-stories`, `agon-oracle`, `jira-ticket`, `issue-link` | See `skill/SKILL.md` |

## Machine config

`~/.config/spec/machine`, written by the first `/spec init` (re-ask with `/spec init --machine`):

| Key | Meaning |
|---|---|
| `rules` | path to a rules-of-record file (confidence, challenge, review, commits); empty = built-in defaults |
| `agon` | `yes` \| `no` |
| `oracle_rules` | path to oracle design rules for `agon goal`/`conquer`; empty = `agon-oracle` rules only |
| `mutation` | starting rung: `agon` \| `tool` \| `subagent` \| `manual` |
| `default_paths` | `<dir>=<preset>, ...` — preset for repos without `.spec` under that dir; empty = ask |
| `policy_paths` | `<dir>=<absolute .md>, ...` — company policy kept outside the repo (pilot, or repos that cannot carry it); repo `.spec` `policy:` wins |

Example:

```
rules: ~/AGENTS.md
agon: yes
oracle_rules:
mutation: agon
default_paths: ~/work=enterprise, ~/oss=team, ~/code=personal, ~/.ai=personal
```

Skill files reference only these keys, never literal paths.

**Built-in defaults** (no machine file or empty `rules`): always state confidence; < 0.90 → one independent challenge (second AI if available, else a fresh-context subagent, flagged as same-model and weaker); < 0.70 → stop and gather evidence; after implementation run the project's tests, typecheck and build.

**Effective agon** = on only when machine `agon: yes` AND `command -v agon` succeeds AND the repo/preset allows it. The Spec line shows the reason when off, e.g. `(agon: off → not installed)`. `agon-oracle` loads only when on.

## Loading

- Enabled addons are the allowed set, not the load set.
- Depth: only the ONE depth addon the depth step selects is loaded.
- Every other addon loads when its hook fires (see the Addons table in `skill/SKILL.md`).

## Resolution order

1. Vendored skill in the repo (`.agents/skills/spec/`, `.claude/skills/spec/`, `.ai/skills/spec/`) → used as-is.
2. `.spec` at the git root (non-git target: the target directory plays the git root here and in step 3).
3. `default_paths` in the machine file (longest matching dir wins).
4. Nothing → `agon: off`, suggest `/spec init`, ask. Company code never goes to external AI by default.

Every run prints: `Spec: preset <x> + addons [...] (via vendored|.spec|default path|asked) (agon: on|off → reason) (rules: <file>|defaults) (policy: <path>|none)`.

## Company policy

Keys, example and checks: [`skill/policy.md`](../skill/policy.md) (ships with the skill).

## `.spec`

```
preset: team
addons: +release-contract, -issue-link
specs.path: .claude/specs/{slug}/spec.md
agon: restricted
agon_engines: claude, codex
repos: backend=../api-server
mode: link
```

`research.max_age: 90` (days) sets when core step 1b research sources are re-fetched before release.

Enterprise adds `ticket.regex`, `ticket.prefixes`, `ticket.fallback`, `branch.pattern`. Full key table: `skill/SKILL.md`.

## Spec lifecycle

- Header carries `Verified at: <git sha>` (non-git target: `dir-hash <sha256> root <dir>`); on resume the commands behind load-bearing VERIFIED claims are re-run.
- `## Changes` (`ADDED:` / `MODIFIED:` / `REMOVED:` + backtick paths, `repo:path` for other repos) is the scope fence and drift anchor.
- `refine` runs before approval: pass = no unresolved HIGH finding.
- At approval the spec emits one `Done when:` line (gate command + AC IDs + "no files outside Changes") for `/goal`, a Stop hook, or a human.
- After the build, **Converge**: re-run load-bearing VERIFIED checks, each AC → PASS (test + output), GAP, or moved out of scope; `## As-built delta`; DONE only with every AC checked.
- `**Status:**` is the enum, optionally followed by ` — note`; spec-check normalizes common synonyms (IMPLEMENTED, BUILT, WIP, …).

## Mutation ladder

`criteria-test-map` proves the tests bite before an AC counts as PASS. Starting rung = machine `mutation`, else the first that works:

1. `agon review --mutate` (flags from the rules file) — only with Agon on.
2. Repo mutation tool: Stryker (JS/TS), mutmut (Python), cargo-mutants (Rust), PIT (Java), go-mutesting (Go).
3. Fresh-context subagent mutates changed lines, runs mapped tests, reports survivors.
4. Manual: flip one condition in changed code; the mapped test must fail.

A survivor on a criterion-mapped test means the criterion is not really checked → fix the test or sharpen the criterion.

## drift-guard (on by default)

`.spec`: `drift: record | living` (default `record`); `addons: -drift-guard` turns it off. Advisory only, never blocks CI.

- Header: `Verified at: <sha>`; covered paths = the `## Changes` block (older specs: `Covers:` / Blast Radius). Generated code: cover the source.
- `record` → DONE specs are frozen; later changes get a new spec with `Supersedes:`. `living` → update in place, bump `Verified at`.
- Before editing code, find specs whose `Covers:` match the files; update, supersede, or note "not affected".
- Tests carry AC IDs in their names; a deleted/renamed AC-linked test is a drift signal.

```sh
skill/scripts/spec-check.sh [repo-dir]              # all specs, one line per finding + summary, exit 0
skill/scripts/spec-check.sh --spec <file>           # one spec
skill/scripts/spec-check.sh --repos backend=../api  # name other repos without writing .spec
skill/scripts/spec-check.sh --stale [repo-dir]      # DONE specs without a sha: check drift since their last commit
skill/scripts/spec-check.sh --strict [repo-dir]     # exit 1 on any finding
skill/scripts/pre-commit-spec-check.sh              # git hook; advisory unless SPEC_STRICT=1 (`/spec init` offers it)
skill/scripts/spec-check.sh --spec <file> --dir-hash <root>  # print the dir-hash anchor for a non-git target
skill/scripts/spec-check.sh --spec <file> --pr-title "<title>"  # PR title vs company policy; exit 0 ok, 1 mismatch, 2 no format
skill/scripts/test-spec-check.sh                    # fixture tests
skill/scripts/test-spec-check-nogit.sh              # non-git target, dir-hash, OPEN-CAP, REFINE-STEPS fixtures
```

Installed with the skill (e.g. `~/.claude/skills/spec/scripts/…`). Reads `specs.path` and `repos` from `.spec` (default folders `.claude/specs` and `.agents/specs`; files `spec.md`, `spec-*.md`, `*-spec.md`). `specs.path` must stay inside the repo; absolute paths, leading `-`, dot components, and symlink escapes are rejected. Spaces in directory names work. Discovered spec paths containing newline, CR, or tab fail with exit 2. Needs only bash 3.2+, git, awk.

The checker returns 0 when no strict finding blocks it, 1 for strict findings, and 2 for a broken invocation, installation, or configured repo that cannot be read. Advisory checks still return 2 for broken configuration.

| Finding | Fires when |
|---|---|
| `STALE` | covered files changed since the anchor (`Verified at`, else `Baseline:`; DONE specs without either: the spec's last commit, only with drift-guard on in `.spec` or `--stale`) |
| `XREPO` | covered `name:path` files in another repo changed since the anchor date |
| `DEAD-CITE` | a VERIFIED citation names a file that is gone, or a line past EOF |
| `STALE-CITE` | VERIFIED `file:line` ranges changed or moved since the spec's anchor (`Date:` → last commit before it) |
| `STATUS-OPEN` | Status DONE/IMPLEMENTED/SHIPPED/COMPLETE with unchecked `- [ ]` under Acceptance Criteria |
| `STATUS-SHIPPED` | Status IN PROGRESS/READY and ≥ 80 % (`--shipped-pct`) of covered paths known to the default branch changed there after the spec (commits in `<anchor>..<default branch>`, anchor = Verified at / Baseline or the commit that added the spec; otherwise a last change strictly after `Date:`) |
| `POINTER` | a short pointer spec names a `…specs/…md` target that does not exist |
| `STATUS-ENUM` | Status does not start with the enum (free text instead of `DONE — note`) |
| `REPEAT-FIX` | ≥ 4 (`--repeat-fix`) fix/hotfix/revert commits on covered paths within 30 days (`--repeat-days`) of `Date:` → escalate, write a bigger spec |
| `NO-STATUS` | no Status header |
| `NO-REVIEW` | Status READY/IN PROGRESS/DONE but no `## Refine` section with a non-empty `Critic:` (or `Critics:`) line |
| `CONTRACT-MISSING` | a `METHOD /path` in `## Contract` is absent from a named repo's default branch or HEAD; lists the branches that have it |
| `CONTRACT-FIELDS` | a consumer's call sites of an endpoint never name a contract field the producer has |
| `UNMERGED` | Status READY/DONE but ADDED paths are not on that repo's default branch |
| `NO-GIT` | target is not in a git repo: file-only checks run, git checks are skipped; counts as a finding under `--strict` |
| `OPEN-CAP` | more than 3 lines tagged OPEN (`OPEN-CAP <spec>: N OPEN (max 3) — decide the rest as ASSUMED with reasoning (core step 5)`) |
| `POLICY-CONFLICT` | `.spec` loosens the company policy (owned format keys, `agon` above `agon.max`, `agon: full` with `agon_engines`, an engine outside `agon_engines`, a dropped required or enabled denied addon) |
| `POLICY-HEADER` / `POLICY-SECTION` | a spec lacks a policy `headers` field, or a policy `sections` heading from READY TO BUILD on |
| `POLICY-TICKET` | the spec's Ticket header has no whole key matching `ticket.regex` |
| `POLICY-WORD` | a spec contains a `words.deny` word (pointer specs get only this check) |
| `POLICY-RULES` / `POLICY-SKILL` | a policy `rules` file, or a `skills` entry's `SKILL.md`, is missing inside the repo |
| `REFINE-STEPS` | Full / tier 2+ spec (`**Depth:**`) whose `## Refine` names a Critic but records no `a–g` step coverage (`Steps:` may omit the conditional b) |

Covered paths come from `## Changes`, else `Covers:`, else the Blast Radius section (backtick paths and path-like first cells; a cell like "backend \`app/x.py\`" resolves `backend` through `repos`).

## link vs vendored

- **link** (personal/team) — only `.spec` is written; the skill itself comes from this repo via `install.sh`.
- **vendored** (company repos) — `/spec init` copies SKILL.md + core.md + chosen addons into the repo (default `.agents/skills/spec/`), bakes the config in, scrubs every machine-file reference and home path (`~/...`), drops Agon addons when agon is off, and adds an ADAPT checklist. The team owns it; it does not depend on this repo.

## Add an addon

1. Create `skill/addons/<name>.md`, under 200 lines, with: title + hook (which core step), `## When to use`, `## What it adds to the spec`, required sections/patterns, `## Anti-patterns`.
2. Add a row to the Addons table in `skill/SKILL.md`.
3. Optionally add it to a preset's `addons:` frontmatter, with scope notes in that preset's body.
4. Keep examples neutral — no employer, product, or customer names.

## Install

```sh
./install.sh            # links skill/ into the skills dir of ~/.ai, ~/.claude, ~/.codex and ~/.gemini/config (only agents that exist)
./install.sh --dry-run  # show what would change
./install.sh --uninstall
```

- Paths come from the repo's own location and `$HOME` — nothing hardcoded.
- Idempotent; existing entries are moved to `~/.ai/backups/` first.
- Other agent dirs: `SPEC_TARGETS="$HOME/.foo/skills $HOME/.bar/skills" ./install.sh` (legacy whitespace-separated absolute paths). For a path containing spaces, use repeatable `./install.sh --target "$HOME/with space/skills"`. The installer checks every target before changing any destination and stores replaced entries in unique `~/.ai/backups/` reservations.
- `SPEC_INSTALL_MODE=copy ./install.sh` copies `skill/` instead of linking it. A copy carries a `.nero-spec-install` marker, so reruns refresh it and `--uninstall` removes it; rerun the installer after `git pull`.

### Windows

Run `./install.sh` from Git Bash (comes with Git for Windows) or WSL. Git Bash creates a real symlink when Windows allows it (Developer Mode or an admin shell) and otherwise falls back to copy mode automatically. In Git Bash, `--target` also accepts Windows paths such as `C:\Users\me\.claude\skills`; under WSL, use the `/mnt/c/...` form. The `spec-check*.sh` scripts need the same bash; CI runs every test on Windows, macOS and Linux.

## Rules this skill defers to

- Confidence thresholds, challenge ladder, review routing, commit rules: the machine `rules` file. Never duplicated here.
- Oracle design (goal/conquer): the machine `oracle_rules` file, via the `agon-oracle` addon.
