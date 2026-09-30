---
name: enterprise
addons: jira-ticket, tier-1-surgical, tier-2-behavioral, tier-3-investigation, tier-4-migration, refine, drift-guard, contract-discovery, success-metrics, criteria-test-map, user-stories, e2e-sweep
agon: ask
agon_engines:
specs.path: .agents/specs/{TICKET}-{slug}/spec.md
branch.pattern: feat/{TICKET}-{slug}
ticket.regex: [A-Z][A-Z0-9]+-\d+
ticket.prefixes:
ticket.fallback:
---

# Preset: enterprise

Company work driven by a tracker. Every spec belongs to a ticket; the company's rules govern tooling and attribution. Prefer a vendored skill (`/spec init`, mode `vendored`) so the team owns it.

## Addon scope

- `success-metrics` — required at tier 2+.
- `criteria-test-map` — always.
- `user-stories` — tier 4 only.
- `refine` — always; its critique (step e) follows the company's `agon` setting: `ask`/`off` → fresh-context subagent in the approved runtime.
- `drift-guard` — on; record mode unless the team keeps living specs.
- `agon-oracle` — not a default; add only when `agon` is `full` or `restricted`.
- `e2e-sweep` — on at release/go-live for repos with a UI or public API; workers run in the approved runtime only; test data and sandbox payments per the company's rules.

## Header and extra sections

```markdown
# [Title]
**Ticket:** KEY-123 (provisional?)
**Status:** SPEC | READY TO BUILD | IN PROGRESS | DONE [— note]
**Date:** YYYY-MM-DD
**Confidence:** 0.XX
```

Earlier enterprise specs that used `READY FOR PLAN` should be changed to `READY TO BUILD` when their approval evidence supports that state; the checker does not treat the old phrase as a synonym.

| Section | Where | Use |
|---|---|---|
| Prerequisites | after What Already Works | Other tickets/teams that must land first. Rec tier 3, Req tier 4 |
| Interfaces | after Implementation Options | Draft types, API shapes, component props. Rec tier 4 |
| Additional Information | before Corrections Log | Designs, wireframes, localization notes, related docs |
| Session Tracking | last | `Date / Session / Description` table. Required every tier |

## Constitution

- **Review tooling** — `agon: ask` until the company confirms. Until then behave as `off`: self-audit + fresh-context subagent in the company-approved runtime + team PR review. Never paste company code into a non-approved tool.
  - `restricted` → only the approved vendors in `agon_engines`; report any reviewer shortfall.
- **Commits** — follow the team's commit convention (ticket key in message, format); confirm with the team.
- **AI trailers** — confirm whether AI co-author trailers are allowed before adding one.
- **Never apply personal signatures** (e.g. a personal or other-org commit signature) or personal tooling here.
- Push only with explicit user confirmation; never to main/master.

## Risk notes

- Other-team source may be inaccessible → tag those claims ASSUMED and list them for the owning team by name.
- Deploy order is agreed with the owning team, never assumed; record who agreed and when.
- Cross-team integration (another team's API, backend PR, new service) → tier 3 minimum; contract table ahead of hypotheses.

## Unconfirmed until the team answers

- `ticket.prefixes`, `ticket.fallback`, `branch.pattern`, `specs.path`, commit convention, AI trailers, allowed AI tooling. `/spec init` asks for each.
