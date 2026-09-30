# Addon: tier-3-investigation

Tier 3 — Investigation / Analysis. Hook: core step 2 (depth); any core escalation trigger forces tier 2+.

## When to use

- Unknown scope, research-heavy, multiple hypotheses to evaluate. Also cross-team integration (another team's API, backend PR, new service): load `contract-discovery` first and put the verified contract table ahead of hypotheses.
- Size: 500+ lines (split on demand via overview + satellite docs).
- Examples: A dashboard performance regression, an API latency spike, a memory leak. The patterns below apply to any investigation -- adapt the examples to your domain.

---

## What it adds to the spec

Required sections:

| Section               | Purpose                                                   |
| --------------------- | --------------------------------------------------------- |
| Executive Summary     | What is unknown, why it matters, scope of investigation   |
| Root Cause / Hypothesis | Initial hypotheses with confidence levels               |
| Implementation Options | A/B/C plans with blast radius + trade-offs               |
| Changes               | `ADDED/MODIFIED/REMOVED:` lines + projected impact         |
| Acceptance Criteria   | Binary pass/fail                                          |
| Out of Scope          | Explicit exclusions                                       |
| Decision Points       | Trade-offs that need human judgment                       |
| Constraints           | Non-negotiable boundaries before exploring solutions      |
| Corrections Log       | Track every wrong claim and its correction                |
| Evidence Chain        | Source-verified data with commands that produced it        |
| Honest Assessment     | Tag claims as PROVEN / PROBABLE / UNVERIFIED              |
| "What We Ruled Out"   | Dead ends with reasons -- saves future sessions from repeating |
| Expected Outcomes     | Projected impact per phase with cost/time projections     |

**Recommended:** Heatmaps, experiment logs, architecture diagrams.

---

## Pattern: Constraints Table (Non-Negotiable)

Define the search space BEFORE exploring solutions. Constraints prevent wasted passes.

```markdown
## Constraints (Non-Negotiable)

| #      | Constraint                          | Rationale                                          |
| ------ | ----------------------------------- | -------------------------------------------------- |
| **C1** | **No infrastructure cost increase** | Current hosting budget is fixed. Non-negotiable.   |
| **C2** | **LCP must stay under 2.5s**        | Core Web Vitals threshold. SEO + UX impact.        |
| **C3** | **Same feature set**                | No removing widgets, filters, or sorting options.  |
| **C4** | **No breaking API changes**         | Other consumers depend on current response shape.  |
| **C5** | **Tests must keep passing**         | No change can cause passing tests to fail.         |

**Implications of C1+C2:**
- CDN tier upgrade is out of budget
- Must optimize within existing architecture
- Image optimization and code splitting are primary levers
```

**Why this works:** Every approach evaluation can reference "violates C2" instead of re-explaining. Implications section pre-answers "but what about..." questions.

---

## Pattern: Corrections Log

Track every wrong claim and its correction. This is the single most important section for multi-pass investigations. Format: original claim, reality, impact on spec.

```markdown
## Corrections Log

| Original Claim                            | Reality                                          | Impact                        |
| ----------------------------------------- | ------------------------------------------------ | ----------------------------- |
| Image lazy-loading caused LCP regression  | Third-party tracking script blocks main thread   | Root cause analysis revised   |
| Filter rendering is the bottleneck        | Filters render in 80ms; data table takes 340ms   | Focus shifted to table        |
| "3 slow API endpoints"                    | **1 slow endpoint called 3 times** (no dedup)   | Single fix instead of 3       |
| Prefetching would fix perceived latency   | Already prefetching; cache headers were wrong    | Cache config fix, not prefetch|
```

**Why this works:** Prevents future sessions from repeating debunked hypotheses. Shows intellectual honesty -- the path to truth matters as much as the final answer.

---

## Pattern: Evidence Chain with Verified Metrics

Every metric must cite its source command. Use `lighthouse`, `grep`, `performance.mark()`, etc.

```markdown
## Current State (Verified Metrics)

### Page Load Performance -- VERIFIED via Lighthouse (5 runs, median)

(`npx lighthouse https://localhost:3000/dashboard --output=json`):

| Metric    | Current | Target  | Gap     |
| --------- | ------- | ------- | ------- |
| LCP       | 4.2s    | < 2.5s  | -1.7s   |
| CLS       | 0.08    | < 0.1   | OK      |
| TBT       | 890ms   | < 200ms | -690ms  |
| FCP       | 1.8s    | < 1.8s  | OK      |

### API Response Times (from 50 requests)

(`curl -w '%{time_total}' https://localhost:3000/api/v1/reports -o /dev/null`):

| Endpoint         | p50     | p95     | p99     |
| ---------------- | ------- | ------- | ------- |
| `/api/v1/reports`| 180ms   | 420ms   | 890ms   |
| `/api/v1/filters`| 90ms    | 150ms   | 210ms   |
| `/api/v1/users`  | 60ms    | 95ms    | 140ms   |
```

**Why this works:** Every number is reproducible. Commands allow re-verification.

---

## Pattern: Honest Assessment

Tag conclusions by confidence level. Never present hypotheses as facts.

```markdown
### Summary

**Honest assessment:** The dashboard LCP can realistically drop from 4.2s
to ~2.8s with the identified optimizations. The primary wins are
(1) eliminating the duplicate API call and (2) optimizing chart image
srcset. Further gains would require infrastructure changes (CDN, edge caching)
which are out of scope per C1.
```

Use these tags in the body of the spec. They grade **conclusions and hypotheses**; the core claim tags (VERIFIED/ASSUMED/OPEN) still grade **facts**. A PROVEN conclusion must rest on VERIFIED facts only.

| Tag            | Meaning                                          |
| -------------- | ------------------------------------------------ |
| **PROVEN**     | Verified via command output or experiment         |
| **PROBABLE**   | Strong evidence but not yet confirmed             |
| **UNVERIFIED** | Hypothesis only -- needs benchmarking or testing  |
| **DEAD**       | Experimentally disproven -- do not revisit        |

Example inline usage:
```markdown
- Duplicate API call removal: **PROVEN** (network tab shows 3 identical requests)
- Chart image srcset optimization: **PROBABLE** (Lighthouse flags it, untested fix)
- Virtual scrolling for data table: **UNVERIFIED** (theoretical, no prototype yet)
- Service worker precaching: **DEAD** (added 200ms overhead in experiment)
```

---

## Pattern: Expected Outcomes Table

Project impact per phase. Include the metrics that matter for your investigation.

```markdown
## Expected Outcomes

### Dashboard Performance (projected)

| Metric    | Current | Phase 1   | Phase 2   | Phase 3     |
| --------- | ------- | --------- | --------- | ----------- |
| LCP       | 4.2s    | ~3.4s     | ~2.8s     | ~2.5s       |
| TBT       | 890ms   | ~600ms    | ~350ms    | ~200ms      |
| API calls | 6       | 3         | 3         | 3           |
| Bundle KB | 245     | 245       | ~210      | ~190        |

Phase 1: Deduplicate API calls (PROVEN fix)
Phase 2: Image optimization + code splitting (PROBABLE)
Phase 3: Component lazy loading (UNVERIFIED)
```

---

## Anti-patterns for Tier 3

- **Do not** present hypotheses as conclusions -- use PROVEN/PROBABLE/UNVERIFIED tags
- **Do not** skip the corrections log -- it is the most valuable section for multi-pass work
- **Do not** evaluate approaches without referencing constraints ("violates C2")
- **Do not** use bare numbers without the command that produced them
- **Do not** explore solutions before defining the constraint space
- **Do not** keep the spec in one massive file -- split into overview + satellite docs when > 20K tokens

