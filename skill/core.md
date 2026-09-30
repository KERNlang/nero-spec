# Core flow

Shared by every preset. Addons plug in at the named hooks. Flow: **spec → refine → build → review → converge/done.** Goal: nothing changes after review.

## Rules of record

Machine `rules` file set → it is canonical for confidence, challenge, review routing, commits; it overrides the defaults below. Point to it; never copy its thresholds or rosters into a spec. Vendored skill → the rules named in its SKILL.md.

Built-in defaults (no `rules` file):
- Always state confidence (`Confidence: 0.XX`) on the spec and every decision.
- < 0.90 → one independent challenge: a second AI if available (Agon when effective agon is on), else a fresh-context subagent — say it is same-model and weaker.
- < 0.70 → stop, gather evidence, say what would raise it. No implementing.
- After implementation: run the project's tests, typecheck and build before calling anything done.

## 1. Understand the request

- Hook: `jira-ticket` / `issue-link` run first (key, link, branch); resuming an existing spec → `refine` steps a + c, then `drift-guard`.
- `stack` profile present → read it first: Edges give the `Callers:` greps, Traps become Tricky inputs, Gate becomes the `Done when` command. Missing → derive the same from manifests in one pass; suggest `/spec init`.
- Rich context (ticket, docs, PR links) → organize it, list the gaps. Brief or verbal → ask until unambiguous.
- **User-facing change** (UI, notifications, emails, sharing or permission semantics) → before writing, restate the concrete reading: which object and scope, where on screen, per what (user, item, session). The user confirms once; record it in `## Intent`. Skip for backend-only work and exact-value style fixes.
- **Skip the spec** when the fix is obvious, single-file and no escalation trigger fires → read, fix, gate. Say so in one line.

## 1b. Research (optional)

- Trigger: requirements depend on external standards, APIs or versions. Read-only; may run before approval.
- Output a `## Sources` table: `| ID | Title | URL | Version / date | Status |`, Status `OK` \| `PARTIAL` \| `UNVERIFIED`.
- Sources older than `.spec` `research.max_age` (days, default 90) are re-fetched before release (`refine` c).

## 2. Pick the depth

- Hook: select ONE depth addon and load only that — `depth-light` (Surgical / Full) or one `tier-*`. None enabled → `depth-light`. Record the pick in `**Depth:**`.
- **Escalation triggers — any ONE forces a spec at Full / tier 2+, regardless of file count:**
  - touches auth, sessions, tokens, guest accounts, payment, deletion or privacy;
  - changes a shared contract (API shape, exported type/enum, generator output, schema) consumed by another module, repo, team, or client;
  - changes persistence shape or needs a data migration;
  - destructive filesystem or process operations (delete/move/overwrite user files, kill, shell-out with user paths);
  - untrusted input reaches an AI prompt or tool call (prompt injection surface);
  - feeds an `agon goal` / `agon conquer` launch;
  - spans sessions or has an unclear root cause (→ tier 3 or 4).
- Auth, guest, payment, persistence, deletion or privacy → `criteria-test-map` is forced, whatever the preset says.
- Sections are required by **trigger, not depth**: contract trigger → Contract table; real multi-option space → Options. One real option → write it plus one line on why the rest are strawmen. Never pad; delete empty sections.

## 3. Discover contracts

- Only when the change crosses a boundary (frontend↔backend, service↔service, repo↔repo, generator↔output, library↔consumers).
- Hook: `contract-discovery`, then `release-contract` for client↔backend releases.

## 4. Write the spec

Base template. Addons add header lines and sections; the depth addon decides which are required. Hooks: `contested-decision-scan` (before drafting), `user-stories`, `success-metrics`.

```markdown
# [Title]
**Date:** YYYY-MM-DD
**Depth:** <Surgical | Full | tier-N>
**Verified at:** <git rev-parse --short HEAD> | dir-hash <sha256> root <dir>
**Confidence:** 0.XX
**Status:** SPEC | READY TO BUILD | IN PROGRESS | DONE [— short note]

## Executive Summary
## Intent
Picked: <confirmed reading or variant link> · Not this: <readings not picked> · Confirmed: YYYY-MM-DD
## Current State / Root Cause
## What Already Works
## Contract (Verified)
| Endpoint | Fields | Producer | Consumers |
|---|---|---|---|

| Field / Behavior | Type | Evidence | Tag |
|---|---|---|---|
## Implementation Options
Real usage: <decision> — <how real callers use it, with evidence>
## Changes
MODIFIED: `path`, `repo:path` — what    (also ADDED:, REMOVED:)
Callers: `symbol` — `rg -n '<pattern>'` → `path` (changes | same), ...
Downstream: <what our output feeds> — what it rejects, owns or assumes (evidence)
History: `git log --oneline -i --grep=fix -- <Changes paths>` → fixes that become Tricky inputs
## Acceptance Criteria
- [ ] AC-1 ...
  Tricky inputs: <named input or state>, <named input or state>
- [ ] AC-n Eval: <property> — baseline vs treatment, n=<k> per arm, rubric <path>
- [ ] AC-n Device check: <what to look at on a device> — screenshot/recording attached before DONE
## Out of Scope
## Open Questions
## Corrections Log
| Original Claim | Reality | Impact |
## Refine
```

- **Verified at** — non-git target: `scripts/spec-check.sh --spec <file> --dir-hash <root>` prints the `dir-hash <sha256> root <dir>` value.
- **Status** — the enum first; anything else goes after ` — `. Never invent a new status word.
- **Intent** — user-facing changes only (step 1). `Picked` is the reading the user confirmed, `Not this` the plausible ones they rejected. Unconfirmed → one OPEN for the whole reading, not one per line, and Status stays SPEC. Not user-facing → omit the section, never leave it empty. Before DONE a human confirms the built behaviour matches `Picked`: the Device check for UI, one real run (sent email, notification, permission attempt) otherwise.
- **Changes** — one line per file or glob, backtick paths, other repos as `repo:path` (name from `.spec` `repos:`), one phrase each. It is the scope fence and the drift anchor (`spec-check.sh` reads it). Generated code → list the source.
- **Contract** — one endpoint row per `METHOD /path`, backtick values (`` `POST /api/x` `` · `` `access_token`, `expires_in` ``), repo names from `repos:`. `spec-check.sh` greps each side's default branch and HEAD for it; other contract facts go in the second table.
- **Callers** — the spec changes the semantics of a function, type or field → one `Callers:` line per symbol: every call site and every construction path (constructor, factory, pool, literal construction, tests), from a cited grep, each marked `changes` or `same`.
- **Acceptance Criteria** — binary pass/fail, testable, numbered `AC-n`, written so a discriminating test falls out. Optional EARS: `WHEN <trigger> [WHILE <state>] THE SYSTEM SHALL <response>`. Non-functional needs (text length, grammar, offline, a11y) are ACs too. Any UI change carries the `Device check:` AC.
- **Tricky inputs** — every AC names ≥ 2 concrete inputs or states (Surgical ≥ 1), never "edge cases". Pick what applies: empty, zero or root values; renamed or aliased fields; repeated or chained calls; partial state left by an earlier step; an object built outside its constructor; a value that exists only in degenerate form; concurrent calls — name the runtime's concurrency model and fire them through the real entry point, not a call counter.
- **A named tricky input is never waived.** Each gets a test through the public entry point. "Safe / no handling needed" is allowed only as a VERIFIED claim citing the code that makes it safe; otherwise it is still tested.
- **Downstream** — whenever our output feeds another layer (parser, consumer, storage, validator, generator, other repo): one line on what that layer rejects, owns (memory, lifetimes) or throws on. "Out of scope" is never an answer for the layer we feed.
- **History** — past fixes in the Changes paths are the cheapest risk list; each relevant one becomes a Tricky input. Skip when the command returns nothing.
- **Preserved behaviour** — "keep as is", verbatim port or byte-identical output is ASSUMED-correct, not VERIFIED: list the odd inputs the preserved code sees (forks, empty graphs, reentry) as Tricky inputs of the AC that preserves it.
- **Real usage** — every ambiguity or decision gets one `Real usage:` line: how existing callers, tests, docs or well-known downstream libraries actually use the API. Any requirement that narrows accepted input, forbids a call sequence, or picks the stricter of two accessors needs this evidence — including known external dependents, not just in-repo callers; without it the decision stays OPEN. Noticing two meanings and picking one is a decision.
- **Corrections Log** — every wrong claim and its correction, whenever discovery took more than a few minutes.
- No task or parallel-work breakdown. Execution fan-out belongs to the runtime.

## 5. Claim tags — evidence binding

- **VERIFIED** — confirmed by reading source, running a command, or calling an API, **and cites the exact artifact**: `path` or `path` › symbol (`:line` only when the line itself matters), `repo@sha:path`, the command plus its load-bearing output, or a captured response. An external source counts only with URL + section + fetch date. No citation → ASSUMED. VERIFIED is provenance, not confidence.
- **Negative evidence** counts only with command + date: "`grep -rn foo src` → 0 hits, 2026-01-31". Absence claims rot fastest.
- **ASSUMED** — inferred from patterns, docs, or memory; not source-checked. Carries its date; older than the anchor → re-check or OPEN (`refine` c).
- **OPEN** — explicitly unknown; needs human input or access not available.
- Every number carries the command that produced it.
- **OPEN cap: max 3 per spec**, ordered by impact: scope > security > UX > technical. Beyond 3 → informed default, tagged ASSUMED with the reasoning.
- Source on the other side inaccessible → that side's claims are ASSUMED; name the owner in Open Questions.

## 6. Self-audit

- Cheap ASSUMED → verify it; VERIFIED without citation → ASSUMED; more than 3 OPEN → cap. A fresh-context agent must be able to execute the spec with zero chat history.
- **Length budget:** Surgical ≤ ~60 lines, Full ≤ ~300. Over → split into phases or satellites. Length does not prevent bugs; named tricky inputs and caller sweeps do.
- Hook: `criteria-test-map` mapping check.

## 7. Save

- Path = `specs.path` with placeholders filled.
- Cross-repo contract → spec lives in the repo whose code changes most; each other repo gets a one-line pointer file at the same path.
- Dry-run or read-only → scratchpad; note it in the header. Never commit unless asked.

## 8. Refine and approve

- Hook: `refine` — mechanical check, contract compare, re-verify, blind spots, critique by risk, decision push, `## Refine` block. It is the pre-build challenge the rules of record require; report the plan delta and re-score.
- **Any OPEN on the recommended option caps confidence below 0.90.** Product-decision OPENs → the human. Technical unknowns → the normal ladder.
- Repo `agon` setting (only when effective agon is on; otherwise `off`): `full` → Agon per the rules of record; `restricted` → only `agon_engines`, passed explicitly, report any shortfall, never silently shrink; `off` → no external AI (self-audit + fresh-context subagent + the preset's human review); `ask` → ask once, record in `.spec`, `off` until answered.
- Hook: `agon-oracle` when the spec feeds `agon goal` / `conquer`.
- **No spec is approved unreviewed.** The `## Refine` block must name its critic (step e) at every depth; no critic → Status stays SPEC.
- **Approval** before building; refine must pass (0 unresolved HIGH). Flag critical ASSUMED claims: "These need verification before implementation: [...]".
- At approval emit one **Done when** line (≤ 4000 chars), usable by `/goal`, a Stop hook, or a human:
  ```
  Done when: `<gate command>` passes; AC-1..AC-n each PASS with named test; no files changed outside Changes.
  ```

## 9. Converge (after build and review)

Checklist, not a review.

- Always re-run the commands behind load-bearing VERIFIED claims (all repos); changed results → Corrections Log. Release or go-live → `refine` a + b + c first.
- Hooks: `criteria-test-map` "Prove the tests"; `drift-guard` AC-link check; `e2e-sweep` device-check rows (UI specs).
- Each AC → `PASS` (test name + load-bearing output line), `GAP` (what is missing), or moved to Out of Scope with a reason. Device-check ACs PASS only with the screenshot/recording. With `## Intent`, DONE also needs the human `Picked` confirmation.
- `git diff --name-only <Verified at>..HEAD` (each repo) vs Changes → list files outside it. dir-hash anchor → re-run `--dir-hash`, record the new value at DONE; files outside Changes cannot be diffed without git, so list the files you edited.
- Add `## As-built delta`: what differs from the spec and why.
- **DONE only when every AC is checked `- [x]` or moved out of scope**, and every consumer in Changes is merged on its shipping branch. Otherwise IN PROGRESS.

## Principles

- Ask who calls it, in what order, with what input, before choosing the strict reading.
- A hazard you name and dismiss in prose is the most likely bug. Test it or cite why it cannot happen.
- Constraints first; root cause only; no bandage fixes. Four fixes in one area → the spec was too small.
