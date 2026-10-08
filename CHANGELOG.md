# Changelog

All notable changes are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- Refine: `agon nero` always gets exactly one engine (`-e <one>`), never a list to auto-pick from.
- Every addon loaded after the Spec line is announced `+<name> (on demand)`; the Spec line lists only loaded addons.
- Non-git targets: the target directory plays the git root for `.spec` and `default_paths`; the `default_paths` example gains a dotfile root.
- Refine: the mutation probe runs in parallel with the step e critic instead of before it, and round 2 is skipped when round 1 only added Tricky inputs or citations.

### Fixed

- A `Critics:` line (plural) no longer triggers a false `NO-REVIEW`.
- Non-git targets no longer exit 0 silently; `spec-check.sh` reports `NO-GIT`.
- `STATUS-SHIPPED` no longer flags a spec whose covered files were committed earlier the same day: hits are commits after the spec's anchor commit (ancestry-based), and the date fallback is strictly after `Date:`.

### Added

- `spec-check.sh --pr-title "<title>"` checks a PR title against the company policy (`pr.title` template or the new optional `pr.regex`) and the spec's ticket key; core step 9 and `jira-ticket` run it before a title is handed over.
- Opt-in preset `operator-reviewed`: one human owns every decision and reviews each slice. Overrides Tricky inputs, the length budget and the OPEN cap while active; the critic stays mandatory and the operator review comes on top; the other overrides ship as addons.
- `/spec init` step 2e: guided company-policy setup that scans the repo's own agent skills (`scripts/list-skills.sh`, with a suggested step per skill) and asks per step which to map; `test-list-skills.sh`.
- Company policy module: one `.md` file (`.spec` `policy:` inside the repo, or machine `policy_paths` for a local file) carries ticket/branch/PR formats, required headers and sections, denied words, required/denied addons, an agon ceiling, allowed engines and the critic runtime, plus a `## Constitution` body. It may only tighten agon and the critic. `spec-check.sh` validates it (exit 2 on unsafe paths, unknown or duplicate keys) and reports `POLICY-CONFLICT`, `POLICY-HEADER`, `POLICY-SECTION`, `POLICY-TICKET`, `POLICY-WORD`, `POLICY-RULES` and `POLICY-SKILL`; `skills` maps steps (understand, design, critic, build, tests, review, tickets, retro) to the company's own repo skills, which own the HOW while the spec owns the WHAT; the machine lookup lives in the optional `spec-check-policy-local.sh`, which vendored copies leave out; `test-spec-check-policy.sh`.
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
