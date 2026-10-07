---
name: spec
description: Use when requirements are unclear, a change spans >3 files or multiple sessions, a cross-boundary contract is involved, the change touches auth/payment/deletion/privacy, destructive file or process operations, or untrusted input reaching an AI, or the work will feed an agon goal/conquer launch — produces a claim-tagged, refined spec before building; or `/spec init` to set up a repo
argument-hint: "[feature or change description] | init [--machine]"
---

Define WHAT before HOW. This file only routes: resolve config → load `core.md` + preset + the addons whose hooks fire → run. Plain markdown; any agent follows the same steps.

## `/spec init`

Argument `init` or `init --machine` → follow `init.md` and stop. Do not write a spec.

## Step 0 — Resolve config

### Machine (per computer)

Read `~/.config/spec/machine` (plain `key: value`):

| Key | Values | Missing / empty |
|---|---|---|
| `rules` | path to a rules-of-record file | built-in defaults in `core.md` |
| `agon` | `yes` \| `no` | `no` |
| `oracle_rules` | path to oracle design rules | `agon-oracle` rules only |
| `mutation` | `agon` \| `tool` \| `subagent` \| `manual` | first rung that works (`criteria-test-map`) |
| `default_paths` | `<dir>=<preset>, ...` e.g. `~/work=enterprise, ~/src=personal, ~/.ai=personal` | no default-path mapping |

- File missing → all defaults; mention `/spec init --machine` once.
- Path set but file unreadable → warn, use defaults.

### Repo (first hit wins)

Non-git target (no git root above it): the target directory plays the git root for the `.spec` lookup and the `default_paths` match.

1. **Vendored skill in the repo** — `.agents/skills/spec/`, `.claude/skills/spec/` or `.ai/skills/spec/` inside the git root (not a symlink back to this skill) → follow that one and stop here.
2. **`.spec` at the git root** → use it (format below).
3. **Default path** — no `.spec`, git root is under a dir in machine `default_paths` (`~` expanded, longest match wins) → use the mapped preset.
4. **Nothing matched** → do NOT assume personal. Repo `agon: off`, suggest `/spec init`, ask which preset to use for this run. Never send company code to an external AI by default.

Merge: preset frontmatter defaults ← `.spec` values. Unknown keys → warn once, ignore.

### Effective agon

`on` only when ALL hold, else `off`:
- machine `agon: yes`;
- `command -v agon` succeeds;
- repo/preset `agon` is `full` or `restricted` (`ask` unanswered = off).

### Spec line

Print exactly one line before anything else:

```
Spec: preset <name> + addons [<a>, ...] (via vendored|.spec|default path|asked) (agon: on|off[ → reason]) (rules: <file>|defaults)
```

Reasons: `not installed`, `machine: no`, `repo: off`, `ask unanswered`. `addons [...]` lists only the addons loaded at that point, not the enabled set; later loads are announced per Step 1.

## `.spec` format

Plain `key: value`, one per line, lists comma-separated, `#` starts a comment.

| Key | Values | Notes |
|---|---|---|
| `preset` | `personal` \| `team` \| `enterprise` \| `operator-reviewed` | required |
| `addons` | `+name, -name, ...` | relative to preset defaults; bare name = `+` |
| `specs.path` | e.g. `.claude/specs/{slug}/spec.md` | Repo-relative; placeholders `{slug}`, `{TICKET}`. A leading `./` and spaces are allowed; absolute paths, leading `-`, `.`/`..` components, and symlink escapes are rejected by bundled scanners. |
| `ticket.regex` | e.g. `[A-Z][A-Z0-9]+-\d+` | only with `jira-ticket` |
| `ticket.prefixes` | e.g. `ABC, XYZ` | only with `jira-ticket` |
| `ticket.fallback` | e.g. `ABC-XXXX` or empty | only with `jira-ticket`; empty = never invent |
| `branch.pattern` | e.g. `{type}/{TICKET}-{slug}` | placeholders `{type}`, `{TICKET}`, `{slug}` |
| `agon` | `full` \| `restricted` \| `off` \| `ask` | what this repo allows |
| `agon_engines` | e.g. `claude, codex` | only with `agon: restricted` |
| `drift` | `record` \| `living` | only with `drift-guard`; default `record` |
| `repos` | e.g. `backend=../api-server, web=../web-client` | other repos named in `## Changes` as `name:path`; read by `scripts/spec-check.sh` and `refine`; proposed by init 0d |
| `stack` | path, default `stack.md` next to `.spec` | stack profile from init 0c; read at core step 1: Edges feed `Callers:` greps, Traps feed Tricky inputs, Gate feeds `Done when` |
| `mode` | `link` \| `vendored` | written by `init.md` |
| `hook` | `yes` \| `no` | advisory pre-commit hook asked once by `init.md` |
| `research.max_age` | days, default `90` | core step 1b: research sources older than this are re-fetched before release |
| `e2e.path` | e.g. `.claude/e2e.md` | only with `e2e-sweep`; default `e2e.md` beside the specs folder |

## Step 1 — Load

- Always: `core.md`, then `presets/<preset>.md` (its body is the constitution and binds for the whole task), then the machine `rules` file if set.
- Enabled addons = preset defaults ± `.spec`. Enabled is the **allowed set**, not the load set.
- **Depth:** load only the ONE depth addon core step 2 selects (`depth-light` or a single `tier-*`). Selected tier not enabled → load it on demand (team/enterprise; personal stays on `depth-light`).
- **Other addons:** load each only when its core hook fires. Missing file → warn, continue.
- `agon-oracle` loads only with effective agon `on`.
- On demand, even when not enabled (blocked only by an explicit `-name` in `.spec`): `contract-discovery` when a boundary is crossed; `release-contract` for client↔backend releases; `refine` at core step 8; `criteria-test-map` when core step 2 forces it.
- An addon line `Replaces core <rule>` wins over that core rule while the addon is loaded; the preset constitution still wins over both.
- Every addon loaded after the Spec line, enabled or not, is announced `+<name> (on demand)` before its hook runs.

## Step 2 — Run

Follow `core.md` step by step. Addons plug in where `core.md` names their hook.

## Addons

| Addon | Hook | One-line purpose |
|---|---|---|
| `jira-ticket` | 1 | Ticket key from branch, `**Ticket:**` header, folder named after key |
| `issue-link` | 1 | Optional issue/PR link in the header |
| `depth-light` | 2 | Two depths: Surgical (half a page) or Full |
| `tier-1-surgical` | 2 | 1–3 file fixes with a clear root cause |
| `tier-2-behavioral` | 2 | Multi-file, user-facing: truth tables, flow impact, dependency matrix |
| `tier-3-investigation` | 2 | Unknown scope: constraints, evidence chain, corrections log |
| `tier-4-migration` | 2 | Codebase-wide / multi-session: phases, satellite docs, handoff |
| `contract-discovery` | 3 | Cross-boundary/repo/team: clients live/dead, hop chain, deploy order, `repo@sha` |
| `release-contract` | 3 | Client↔backend releases: old clients in the wild, compat window |
| `contested-decision-scan` | 4 | Experimental, off by default: contested readings → Breaks tests, settled only by consumer evidence, else conservative pick |
| `user-stories` | 4 | P1–P3 stories, each independently testable |
| `success-metrics` | 4 | Measurable tech-agnostic targets, separate from acceptance criteria |
| `criteria-test-map` | 6, 9 | Every AC and tricky input ↔ test both ways; `Eval:` ACs for agent-behaviour artifacts; mutation ladder proves the tests |
| `refine` | 1 (resume), 8, release | Spec-check, contract compare both sides, re-verify claims, tricky-input/caller/real-usage check + blind spots → ACs, critique by risk, max 2 rounds, `## Refine` block with step coverage; re-fetches stale research |
| `drift-guard` | 1, 4, 9 | `Verified at` (git sha, or dir-hash for non-git targets) + `## Changes` as anchor, STALE detection, supersede/living; `scripts/spec-check.sh`, optional pre-commit hook |
| `agon-oracle` | 8 | Oracle fixtures for `agon goal`/`conquer`, holdouts, promotion rule |
| `e2e-sweep` | 9, release, on demand | Live personas × features sweep + visual audit before release/overnight; `Device check:` ACs become rows (`scripts/e2e-matrix.sh`); project file `e2e.md` |
| `visual-grid` | 4, 9 | One low-RAM screenshot grid (desktop + mobile × light + dark) per UI change (`scripts/shotgrid.mjs`); hard gate replacing `Device check:` for UI ACs; used by `operator-reviewed` |
| `ticket-interpretation` | 1, 4, 8 | Purpose and authority + Ticket interpretation (Accepted/Proposed/Open) replace `## Intent`; ticket re-read before approval and PR; used by `operator-reviewed` |
| `changed-things` | 4 | Changed things table (kind, contract change, used by, evidence) + Precedent replace `Callers:` / `Real usage:`; used by `operator-reviewed` |
| `completion-conditions` | 8, 9 | `## Completion conditions`, per-AC met/not met, `## What was not done` replace `Done when` / As-built delta; used by `operator-reviewed` |

Task: $ARGUMENTS
