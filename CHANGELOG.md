# Changelog

All notable changes are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and versions follow [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
