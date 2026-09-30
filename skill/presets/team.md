---
name: team
addons: tier-1-surgical, tier-2-behavioral, refine, drift-guard, contract-discovery, criteria-test-map, success-metrics, issue-link, agon-oracle
agon: full
specs.path: .claude/specs/{slug}/spec.md
branch.pattern: {type}/{slug}
---

# Preset: team

Work with collaborators: shared repos, public APIs with downstream consumers, PRs others review. No ticket requirement; the slug is the identity.

## Addon scope

- `success-metrics` — tier 2 only; tier 1 skips it.
- `criteria-test-map` — always.
- `issue-link` — optional; never blocks a spec.
- Tier 3/4 load on demand when a trigger demands them (SKILL.md Step 1).
- `refine` — tier 1: steps a + d + one critic; tier 2+: a–g. `drift-guard` — on; `drift: living` for long-lived shared code.
- `e2e-sweep` — suggested per repo with a UI or public API (`addons: +e2e-sweep`); before releases only. Not a default.

## Header

```markdown
# [Title]
**Issue:** <link>    (omit when none)
**Date:** YYYY-MM-DD
**Confidence:** 0.XX
**Status:** SPEC | READY TO BUILD | IN PROGRESS | DONE [— note]
```

## Constitution

- Rules of record: machine `rules` file (core.md defaults when unset).
- Effective agon on → challenge and review through Agon on the live roster; off → core.md fallback, and name the human PR reviewer.
- Feeds `agon goal` / `conquer` → `agon-oracle` (+ machine `oracle_rules`).
- **Repos with an org commit-signature rule:** signature exactly as the rules of record prescribe. No rules file → ask before adding any signature or AI trailer.
- Commits granular, never amend without asking, native `git` only; feature branch + PR, never push main/master without explicit confirmation.

## Risk notes

- A `## Changes` block listing generated files is wrong — point at the source that generates them.
- Public APIs (e.g. a shared library) have downstream consumers in other repos: `contract-discovery` must enumerate them with `repo@sha`.
- Generator changes are shared contracts: enumerate every consumer of the output.
- Collaborators read the spec cold: no private shorthand, every claim cited.
