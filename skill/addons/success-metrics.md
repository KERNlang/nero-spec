# Addon: success-metrics

Measurable outcome targets, kept separate from pass/fail acceptance criteria. Hook: core step 4, section after Acceptance Criteria.

## When to use

- Default: required at tier 2+ / Full depth; skip at tier 1 / Surgical. Presets may narrow this.
- The change has a user-visible or operational goal beyond "it works" (speed, adoption, error rate, cost).

## What it adds to the spec

```markdown
## Success Metrics
| # | Metric | Baseline | Target | How measured | When |
|---|---|---|---|---|---|
| SM-1 | Checkout completion rate | 72% (analytics, 2026-01-31) | ≥ 75% | weekly funnel report | 4 weeks after release |
| SM-2 | p95 search latency | 820ms (`<load test cmd>`) | < 400ms | same load test | before release |
```

## Rules

- **Measurable** — a number, a unit, a measurement method, a point in time.
- **Technology-agnostic** — describe the outcome ("users find a product in under 3 searches"), not the mechanism ("Redis cache hit rate").
- **Baseline carries evidence** like any claim: command, dashboard + date, or ASSUMED.
- **Separate from Acceptance Criteria**: criteria are binary and testable in CI; metrics are observed, may take weeks, and can miss without the change being wrong.
- **Never oracle fixtures** — `agon-oracle` and `criteria-test-map` ignore this section.
- 1–5 metrics. More means the goal is unclear.

## Anti-patterns

- Restating an acceptance criterion as a metric ("tests pass").
- Metrics without a baseline or without a measurement method.
- Implementation metrics ("use a cache") dressed up as outcomes.
- Feeding a metric into an oracle fixture or CI gate.
- Vanity targets nobody will measure after release.
