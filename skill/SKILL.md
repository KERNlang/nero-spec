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
| `policy_paths` | `<dir>=<absolute .md>, ...` e.g. `~/work/acme=~/policies/acme/policy.md` | no machine policy; a local company policy for repos that do not ship their own (longest dir match) |

- File missing → all defaults; mention `/spec init --machine` once.
- Path set but file unreadable → warn, use defaults.

### Repo (first hit wins)

Non-git target (no git root above it): the target directory plays the git root for the `.spec` lookup and the `default_paths` match.

1. **Vendored skill in the repo** — `.agents/skills/spec/`, `.claude/skills/spec/` or `.ai/skills/spec/` inside the git root (not a symlink back to this skill) → follow that one and stop here.
2. **`.spec` at the git root** → use it (format below).
3. **Default path** — no `.spec`, git root is under a dir in machine `default_paths` (`~` expanded, longest match wins) → use the mapped preset.
4. **Nothing matched** → do NOT assume personal. Repo `agon: off`, suggest `/spec init`, ask which preset to use for this run. Never send company code to an external AI by default.

Merge: preset frontmatter defaults ← `.spec` values. Unknown keys → warn once, ignore.

### Policy (company module)

One file holds a company's conventions so the skill itself stays unchanged. Resolve: `.spec` `policy:` (repo-relative `.md` inside the git root, no symlinks) → else machine `policy_paths` → else none. Invalid or unreadable policy → stop and report; never run with half a policy.

Frontmatter: flat `key: value`, whole-line `#` comments, unknown or duplicate key = invalid. `format: nero-spec-policy/v1` is required.

| Key | Meaning |
|---|---|
| `ticket.regex`, `ticket.prefixes`, `ticket.fallback`, `branch.pattern` | Owned by the policy: they replace the preset and `.spec` values |
| `pr.title` | PR title format, e.g. `<feat\|fix>: <Summary> #ORG-<n>` (`<n>` = digits, `<a\|b>` = one of, other `<x>` = any text) |
| `pr.regex` | Optional exact ERE for the title when the format has rules a template can't say (case, scope); wins over `pr.title` for `--pr-title` |
| `headers` | Header fields every spec must carry, e.g. `Ticket, Confidence` |
| `sections` | Sections required from READY TO BUILD on, e.g. `Release Notes` |
| `words.deny` | Words a spec must never contain (internal tool names, codenames) |
| `addons.require`, `addons.deny` | `.spec` cannot remove a required addon or enable a denied one |
| `agon.max` | `off` \| `ask` \| `restricted` \| `full` — ceiling; effective repo agon = the lower of `.spec`/preset and this |
| `agon_engines` | Allowed engines; effective list = `.spec` list ∩ this |
| `critic` | `subagent` \| `agon` \| `any` — who may run the refine critique (`subagent` = never an external AI) |
| `rules` | Rules-of-record files (repo-relative), read with the machine `rules` file |
| `skills` | The company's own repo skills per step: `<step>=<skill>[\|<skill>], ...`, steps `understand`, `design`, `critic`, `build`, `tests`, `review`, `tickets`, `retro` |
| `skills.path` | Repo-relative folders holding `<skill>/SKILL.md`, comma list, first match wins; default `.agents/skills`, `.claude/skills`, `.ai/skills`. A `SKILL.md` that is a symlink, or a skill folder resolving outside the repo, never counts |

**Repo skills per step.** When the policy names a skill for a step, load that skill at the step and announce `+skill <name> (policy: <step>)`; several names = the skill matching the touched area (e.g. frontend vs backend), else the first. Steps: `understand` core 1 (unclear ticket, terms) · `design` core 4 Implementation Options · `critic` refine step e, run in a fresh context and still bound by agon/`critic` · `build` implementation after approval · `tests` writing the tests `criteria-test-map` names · `review` before core 9 Converge · `tickets` splitting an approved spec · `retro` after Converge. Split: the spec owns WHAT (ACs, claim tags, evidence, gates, Status); the repo skill owns HOW (code style, test patterns, review axes) and wins on those. A skill never lowers a spec gate.

Body: `## Constitution` (binding prose) and optional `## Header and extra sections`. Precedence: the policy may only tighten agon and the critic, never loosen them; its formats win over preset and `.spec`; `.spec` still owns operational keys (`stack`, `repos`, extra addons). `scripts/spec-check.sh` enforces the mechanical part (`POLICY-*` findings).

### Effective agon

`on` only when ALL hold, else `off`:
- machine `agon: yes`;
- `command -v agon` succeeds;
- repo/preset `agon` is `full` or `restricted` (`ask` unanswered = off), capped by the policy `agon.max`.

### Spec line

Print exactly one line before anything else:

```
Spec: preset <name> + addons [<a>, ...] (via vendored|.spec|default path|asked) (agon: on|off[ → reason]) (rules: <file>|defaults) (policy: <path>|none)
```

Reasons: `not installed`, `machine: no`, `repo: off`, `ask unanswered`, `policy: off`. `addons [...]` lists only the addons loaded at that point, not the enabled set; later loads are announced per Step 1.

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
| `policy` | repo-relative `.md`, e.g. `.nero-spec/policy.md` | company module (Step 0 Policy); wins over machine `policy_paths` |
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

- Always: `core.md`, then `presets/<preset>.md` (its body is the constitution and binds for the whole task), then the policy body if one resolved, then the policy `rules` files and the machine `rules` file if set.
- Policy `addons.require` are enabled; `addons.deny` are blocked even on demand.
- Enabled addons = preset defaults ± `.spec`. Enabled is the **allowed set**, not the load set.
- **Depth:** load only the ONE depth addon core step 2 selects (`depth-light` or a single `tier-*`). Selected tier not enabled → load it on demand (team/enterprise; personal stays on `depth-light`).
- **Other addons:** load each only when its core hook fires. Missing file → warn, continue.
- `agon-oracle` loads only with effective agon `on`.
- On demand, even when not enabled (blocked only by an explicit `-name` in `.spec`): `contract-discovery` when a boundary is crossed; `release-contract` for client↔backend releases; `refine` at core step 8; `criteria-test-map` when core step 2 forces it.
- An addon line `Replaces core <rule>` wins over that core rule while the addon is loaded; the policy constitution, then the preset constitution, still win over both.
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
