# Changelog

All notable changes are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- `spec-check.sh`: an unknown company-policy key warns once on stderr and is ignored; any other invalid policy exits 3 (was 2, shared with "no policy").
- Every non-canonical status (`BUILT`, `IMPLEMENTED`, `WIP`, `READY`, ...) now reports `STATUS-ENUM`; aliases still classify, so `BUILT` counts as DONE for `STATUS-OPEN`.
- `core.md`: VERIFIED needs a check that could have shown the opposite, an absence claim needs a search or listing, never one guessed 404; a tricky input gets a test only when a realistic bug would break it, in the system-under-test's existing test file; repeated nits are never optional and the last review covers the whole diff against the base branch; the newer rule wins and a waived written rule needs the owner's OK and goes in the PR text.
- Refine: if the critic cannot run, Status stays SPEC; the critic audits the check behind VERIFIED claims; blind second design; lazy wins plus an over-engineering pass, recorded with a 0-10 score in `## Refine`.
- Refine: `agon nero` always gets exactly one engine (`-e <one>`), never a list to auto-pick from.
- Every addon loaded after the Spec line is announced `+<name> (on demand)`; the Spec line lists only loaded addons.
- Non-git targets: the target directory plays the git root for `.spec` and `default_paths`; the `default_paths` example gains a dotfile root.
- Refine: the mutation probe runs in parallel with the step e critic instead of before it, and round 2 is skipped when round 1 only added Tricky inputs or citations.

### Fixed

- A `Critics:` line (plural) no longer triggers a false `NO-REVIEW`.
- Non-git targets no longer exit 0 silently; `spec-check.sh` reports `NO-GIT`.
- `STATUS-SHIPPED` no longer flags a spec whose covered files were committed earlier the same day: hits are commits after the spec's anchor commit (ancestry-based), and the date fallback is strictly after `Date:`.

### Added

- Status `IN REVIEW`: built, PR open; the spec ships in that PR, so merging it makes the spec DONE. Treated like IN PROGRESS by every check.
- Post-deploy ACs: `- [ ] AC-n (post-deploy: <env>, <owner>) ...` stays unchecked without tripping `STATUS-OPEN` or `PR-OPEN-AC`; `criteria-test-map` records `PASS <date> <env>` evidence for manual rows run before the PR.
- `spec-check.sh --pr-title --spec` reports `PR-OPEN-AC` (exit 1) while any acceptance criterion is unchecked.
- Opt-in preset `operator-reviewed`: one human owns every decision and reviews each slice. Overrides Tricky inputs, the length budget and the OPEN cap while active; the critic stays mandatory and the operator review comes on top; the other overrides ship as addons.
- Company policy module: one `.md` file (in the repo via `.spec` `policy:`, or on one machine via `policy_paths`) holds a company's formats, required headers and sections, denied words, addon rules, AI ceilings and repo skills per step; `.spec` can only tighten it. `spec-check.sh` reports `POLICY-*` findings and checks PR titles (`--pr-title`); `/spec init` step 2e detects existing lint rules and repo skills (`scripts/list-skills.sh`) and writes the file.
- Addons `ticket-interpretation` (replaces Intent), `changed-things` (replaces Callers / Real usage) and `completion-conditions` (replaces Done when / As-built delta); each states the core rule it replaces. `visual-grid` now replaces the per-AC `Device check:` for UI ACs.
- Addon `visual-grid` with `scripts/shotgrid.mjs`: one low-RAM screenshot grid (desktop + mobile × light + dark) per UI change.
- `spec-check.sh` findings `NO-GIT`, `OPEN-CAP` and `REFINE-STEPS`; `--dir-hash` prints a `dir-hash <sha256> root <dir>` anchor so non-git targets can be drift-checked; `test-spec-check-nogit.sh`.
- Core step 1b Research (`## Sources` table) and `.spec` key `research.max_age` (default 90 days).
- `Eval:` acceptance criteria and an eval rung in `criteria-test-map`: baseline vs treatment arms, rubric before runs, `PASS` / `NO-SIGNAL` / `FAIL`.
- `## Refine` records step coverage (`Steps: a–g`); the template gains a `**Depth:**` header.
- `bench/2026-09-29-nero-vs-spec-kit/`: sanitized data from a 1:1 build pilot against Spec Kit (specs, oracle, gate logs, reviews).
- README benchmark now compares Nero Spec with Kiro, OpenSpec and Spec Kit on the same 12 cases.
- Windows support: `install.sh` runs in Git Bash and WSL, uses real symlinks when Windows allows them and falls back to a marked copy otherwise. CI now runs every test on Windows too.
- `SPEC_INSTALL_MODE=copy` installs a copy instead of a symlink on any OS.
- `.gitattributes` keeps scripts LF on Windows checkouts.

## [0.1.0] - 2026-09-30

First public release.

### Added

- `/spec` skill: short, claim-tagged specs (VERIFIED / ASSUMED / OPEN) with a mandatory critic pass before building, and convergence on every acceptance criterion.
- Presets `personal`, `team` and `enterprise`, and per-repo addon switching in `.spec`.
- Addons: agon-oracle, contested-decision-scan (experimental, off by default), contract-discovery, criteria-test-map, depth-light, drift-guard, e2e-sweep, issue-link, jira-ticket, refine, release-contract, success-metrics, user-stories, and tiers 1–4.
- `spec-check.sh` with contract, drift, cross-repo, status and review checks, plus a pre-commit hook.
- `install.sh`, which links the skill into the agents it finds, with safe backups and `--target` / `--dry-run`.
- CI on Linux and macOS, shellcheck, contributor docs and issue templates.

[Unreleased]: https://github.com/KERNlang/nero-spec/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/KERNlang/nero-spec/releases/tag/v0.1.0
