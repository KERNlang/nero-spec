# `/spec init`

Set up this machine (once) and one repo: pick a preset, adjust addons, write the config. Never commit. Never overwrite without showing the diff and asking.

## 0. Machine (first run, or `/spec init --machine`)

`~/.config/spec/machine` missing, or `--machine` given → ask these first, one at a time. `--machine` → stop after this section.

1. **`rules`** — path to your rules-of-record file (confidence, challenge, review, commits). Prefill with the first existing file among `AGENTS.md`/`CLAUDE.md` in the agent config dirs of this machine. Empty = core.md built-in defaults.
2. **`agon`** — run `command -v agon`. Found → default `yes`; not found → default `no` and say so.
3. **`oracle_rules`** — only if `agon: yes`. Path to oracle design rules; prefill if an agon playbook file exists on disk. Empty = `agon-oracle` rules only.
4. **`mutation`** — `agon` (if `agon: yes`), `tool`, `subagent`, `manual`. Default: `agon` if available, else `subagent`.
5. **`default_paths`** — optional. Folders on this machine whose repos use a preset without a `.spec`, as `<dir>=<preset>` pairs, e.g. `~/work=enterprise, ~/src=personal, ~/.ai=personal`. Empty = every repo without `.spec` is asked (SKILL.md Step 0). Never map a folder holding company code to `personal` or `team`.

Show the file, ask, then write it (create `~/.config/spec/` if needed):

```
rules: <path or empty>
agon: yes
oracle_rules: <path or empty>
mutation: agon
default_paths: <dir>=<preset>, ... or empty
```

Existing machine file → show it and the diff before overwriting.

## 0b. Check the repo

- Git root: `git rev-parse --show-toplevel`. Not a git repo → stop and say so.
- Existing `.spec` or vendored skill (`.agents/skills/spec/`, `.claude/skills/spec/`, `.ai/skills/spec/`) → show it, ask: keep, edit, or replace. Replace/edit → show the full diff before writing.
- Default path match (SKILL.md Step 0) → offer that preset as the default.

## 0c. Stack scan (read-only, local)

Scan the git root only: manifests (`package.json`, `angular.json`, `*.csproj`, `*.sln`, `pom.xml`, `build.gradle*`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, …), top-level folders, CI files. Nothing leaves the machine; agon never runs here.

Draft a stack profile, ≤ 15 lines, each line with the file it came from:
- **Stack** — languages, frameworks, versions; monorepo → one line per package.
- **Role** — `backend`, `frontend`, `mobile`, `library`, `cli`, or several.
- **Edges** — where routes are declared, where API clients live, how objects are built (DI container, factories, pools) — as `rg` patterns that find them.
- **Gate** — test, typecheck, build commands. **Mutation** — the repo's tool, if any.
- **Traps** — up to 3 stack pitfalls that become Tricky inputs (e.g. async over sync, missed unsubscribe, transaction boundary, effect runs twice).

Show it; the user edits or accepts. Accepted → `stack.md` next to `.spec`. Refine step c re-checks it when a manifest changes.

## 0d. Partner repos (only when Role has `backend` or `frontend`)

- Look one level up from the git root for repos with the opposite role (same scan, manifests only). Never further; never outside the user's workspace.
- Propose: `repos: backend=../api, web=../web-client`. The user confirms each entry; unconfirmed → not written. Company repos stay under the repo's `agon` setting.
- Confirmed → offer a seed Contract: backend route strings vs frontend call strings from the Edges patterns, matched as plain strings, listed as `| Endpoint | Fields | Producer | Consumers |` rows tagged ASSUMED. Written to the scratchpad for the first spec that needs it, never into the repo unasked.

## 1. Interview

One question at a time. Always offer the default from the chosen preset; Enter = accept.

1. **Preset** — `personal` (solo), `team` (working with others), `enterprise` (company work), `operator-reviewed` (one human owns every decision and reviews each slice). Unknown location → no default; say that company code never goes to external AI until answered.
2. **Addons** — show the preset's defaults marked `[x]`, all others `[ ]`, one line each (table in SKILL.md). Ask which to add or remove. Note: task/parallel breakdown is not an addon.
3. **Enterprise only**, one at a time:
   - Jira prefixes (`ticket.prefixes`) — empty = ask for the full key each time;
   - fallback key (`ticket.fallback`) — empty = never invent one;
   - branch pattern (`branch.pattern`), default `feat/{TICKET}-{slug}`;
   - commit convention and whether AI co-author trailers are allowed (goes into the constitution, not `.spec`);
   - allowed AI tooling: `full`, `restricted` (+ which engines → `agon_engines`), `off`. Unsure → `ask`.
   - company policy: offer to collect the answers above (plus required headers/sections, denied words, critic runtime) into one policy file instead of `.spec` and a vendored copy — in the repo (`.spec` `policy:`), or kept on this machine until it is shared (machine `policy_paths`). Shape: REFERENCE.md "Company policy". Then run `scripts/spec-check.sh` to validate it.
4. **`agon`** (personal/team) — confirm the preset default. Machine `agon: no` → note that the repo setting has no effect on this machine.
5. **`drift`** — unless `drift-guard` was removed: `record` (default) or `living`.
6. **`specs.path`** — show the preset default; accept or change. Keep it repo-relative; the bundled scanners reject absolute paths, leading `-`, `.`/`..` components, and symlink escapes. Directory names may contain spaces.
7. **Mode** — `link` (default for personal/team) or `vendored` (default for enterprise/company repos, required when the team must own the skill or must not depend on personal paths).
8. **Pre-commit hook** — ask once per repo: "Install the advisory spec pre-commit hook (never blocks unless `SPEC_STRICT=1`)?" Default no. Record `hook: yes|no` in `.spec` so it is never asked again.
9. **E2E sweep** — only if the repo has a UI (web/mobile/desktop) or a public API. Ask: "Enable `e2e-sweep` (live personas × features + visual audit before release / overnight)?" Default: enterprise yes, personal/team no. Yes → `addons: +e2e-sweep` (enterprise: already on) and draft `e2e.md` (2d).

Then show the result and ask to write.

## 2a. Mode `link` — write `.spec` only

Write `<git root>/.spec`, only keys that differ from the preset, plus `preset` and `mode`:

```
preset: team
addons: +release-contract, -issue-link
mode: link
```

- Personal/team repos: suggest adding `.spec` to the commit, but do not commit.
- Print the resulting Spec line (SKILL.md) as a check.

## 2b. Mode `vendored` — copy into the repo

Ask for the location; default `.agents/skills/spec/`. Write:

```
<location>/
  SKILL.md        new router that reads the repo .spec (template below)
  core.md         copy, then scrubbed
  addons/<name>.md   only the chosen addons, scrubbed
  scripts/           spec-check.sh, spec-check-lib.sh, spec-check-contract.sh, spec-check-policy.sh (never spec-check-policy-local.sh), pre-commit-spec-check.sh (refine and drift-guard call them); + e2e-matrix.sh with e2e-sweep
<git root>/.spec     machine-readable repo config shared by the checker, hook, and E2E matrix
```

Scrub every copied file:

- Remove every reference to the machine file and to any path under the user's home (`~/...`). When the chosen preset is enterprise, remove references to the personal/team presets.
- Machine `rules` / `oracle_rules` / `mutation` references → "the rules of record in SKILL.md" / the team's oracle rules / the mutation rung the team chose. Never copy the content of the user's own rules files into a company repo.
- Built-in defaults in `core.md` stay unless the team names its own rules.
- `agon: off` → do not copy `agon-oracle`; in `core.md` keep only the `off` bullet under Challenge; in `criteria-test-map` drop the `agon` rung.
- `agon: restricted` or `full` → keep `agon-oracle`; enterprise oracle rules unknown → enterprise ADAPT checklist.
- Prove home and machine references are gone: `grep -rnE '~/|[Mm]achine' <location>` → 0 hits. For enterprise, also check `grep -rn 'presets/' <location>` → 0 hits. Show the commands and results.

Write a minimal `<git root>/.spec` with `preset: <chosen preset>`, `mode: vendored`, and the chosen `specs.path`. Add only other keys needed for this repo, including `agon` and `agon_engines` if set. Keep the same values in the vendored router's human instructions; `.spec` is the machine-readable source for scripts. A custom `specs.path` must be tested with `spec-check.sh --strict`, the strict pre-commit hook on a staged spec, and `e2e-matrix.sh` when copied.

Vendored `SKILL.md` template:

For personal/team vendoring, use that preset's constitution and omit the enterprise-only ADAPT checklist and interview keys.

```markdown
---
name: spec
description: <same triggers as the source SKILL.md>
argument-hint: "[feature or change description]"
---

Define WHAT before HOW. Read the repo `.spec`, load `core.md` + the addons below, then run core step by step.

## Config
Read `preset`, `specs.path`, `addons`, ticket/branch keys, and `agon` from the repo `.spec`.

Print: `Spec: vendored + addons [...]`

## Rules of record
<confidence, challenge and review policy of this team, or "self-audit + fresh-context subagent in the approved runtime + team PR review">

## Constitution
<the chosen preset constitution, with answers from the interview filled in>

## Header and extra sections
<from the preset>

## ADAPT checklist
- [ ] Jira prefixes and fallback key confirmed with the team
- [ ] Branch pattern matches what the team actually uses
- [ ] Spec folder location agreed (in repo? gitignored?)
- [ ] Commit convention and AI trailer policy confirmed
- [ ] Allowed AI tooling confirmed in writing; engines listed if restricted
- [ ] Review policy (who approves specs, PR reviewers) named
- [ ] Team-specific contract boundaries and risk notes added
- [ ] Examples in addons still neutral / replaced with team examples

Task: $ARGUMENTS
```

- For enterprise vendoring, leave the ADAPT checklist in place until the team ticks every item.
- Keep the vendored `SKILL.md` instructions and the repo `.spec` consistent; scripts read `.spec` directly.

## 2c. Pre-commit hook (only on yes)

- Hook dir: `git config core.hooksPath` if set (a committed dir such as `.husky/` → it is a repo change: show the diff and ask again), else `git rev-parse --git-path hooks`.
- Script path: the skill's `scripts/pre-commit-spec-check.sh` — the installed skill dir for `link`, the vendored copy for `vendored`.
- No `pre-commit` there → write `#!/bin/sh` + `"<script path>" || exit $?`, `chmod +x`.
- Existing `pre-commit` → never overwrite. Show it, then append the same line (before a final `exec …` line if it has one). Already contains the script path → leave it.

## 2d. `e2e.md` draft (only on e2e yes)

Path: `.spec` `e2e.path` if set, else `e2e.md` beside the specs folder (`.claude/e2e.md`, enterprise `.agents/e2e.md`). Fill the skeleton in `addons/e2e-sweep.md` from what is discoverable, each prefilled value marked with its source; then ask only for what is still empty, one question at a time:

- **Start / health** — `package.json` scripts, `Makefile`/`justfile`, `docker-compose*.yml`, migration tool config (alembic, prisma, knex, rails), a `/health*` route (`rg -n 'health'`).
- **Branches** — `git branch -a`: integration/release naming pattern → offer it as a rule ("newest `release/*`").
- **Driver** — `ios/` or `*.xcodeproj` → iOS simulator (idb); `android/` → adb/Maestro; web framework or `playwright.config.*` → Playwright; none of these → API-only.
- **i18n** — locale dirs (`locales/`, `i18n/`, `*.lproj`, `values-*`) → locale list; ask for the largest-text rule.
- **Design source** — token/theme files (`constants/`, `theme*`, `tokens*`, `tailwind.config.*`), a shared components dir, a UI rules file (`AGENTS.md`, `DESIGN.md`). `design_source: code`.
- **Ask** — personas + seed recipe, feature list (offer the top-level screens/routes found), payment sandbox, output dir, project rules.
- **Figma** — ask only if the user wants `design_source: figma`; then file URL + frame map (screen → frame). Default off.

Show the draft and ask to write it; never overwrite an existing `e2e.md` without the diff.

## 3. Finish

- List the files written, and the files NOT written because the user declined.
- Never commit, never push. Suggest who on the team should review a vendored skill.
