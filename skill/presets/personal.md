---
name: personal
addons: depth-light, refine, drift-guard, criteria-test-map, agon-oracle
agon: full
specs.path: .claude/specs/{slug}/spec.md
branch.pattern: {type}/{slug}
---

# Preset: personal

Solo projects. No ticket — the slug is the identity.

## Addon scope

- `criteria-test-map` — when the spec feeds `agon goal` / `agon conquer`, and whenever core step 2 forces it (auth, guest, payment, persistence, deletion, privacy).
- `depth-light` — most work lands in Surgical; Full when an escalation trigger fires. No tier-3/4: Full + satellite docs instead.
- `refine` — Surgical: steps a + d + one critic; Full: a–g. `drift-guard` — automatic via `## Changes`.
- Suggested per repo: client↔backend apps (e.g. a mobile app with its own API) → `addons: +release-contract` in `.spec`.
- Suggested per repo with a UI or public API: `addons: +e2e-sweep` for a pre-release / overnight live sweep. Not a default.

## Header

```markdown
# [Title]
**Date:** YYYY-MM-DD
**Confidence:** 0.XX
**Status:** SPEC | READY TO BUILD | IN PROGRESS | DONE [— note]    (multi-session only)
```

## Constitution

- Rules of record: machine `rules` file (core.md defaults when unset).
- Effective agon on → Agon is the multi-AI runtime for challenge and review; off → core.md fallback.
- Feeds `agon goal` / `conquer` → `agon-oracle` (+ machine `oracle_rules`).
- Commits: granular, never amend without asking, native `git` only. Default attribution of the running agent unless the rules of record prescribe a signature.
- Branch suggestions use `branch.pattern`; never rename an existing branch unasked.
- One push per finished feature; never push main/master without explicit confirmation.

## Risk notes

- Generator changes are shared contracts: enumerate every consumer of the output.
- A `## Changes` block listing generated files is wrong — point at the source that generates them.
