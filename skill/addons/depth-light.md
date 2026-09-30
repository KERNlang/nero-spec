# Addon: depth-light

Two depths instead of four tiers. Hook: core step 2.

## When to use

- Solo or small projects where most changes are either a quick fix or a real feature.
- Default when no depth addon is enabled.
- Do not combine with `tier-*` addons; if both are enabled, tiers win and this addon is ignored.

## What it adds

A binary depth decision stated in the spec header: `**Depth:** Surgical | Full`.

## Surgical

- 1–3 files, clear scope, no escalation trigger fires.
- Sections: Executive Summary, Root Cause, Changes (+ `Callers:` when a symbol's semantics change), Acceptance Criteria (≥ 1 Tricky input each). One plan. ≤ ~60 lines. Refine: steps a + d + one critic (e).
- Optional: What Already Works (recommended when scope creep is likely), Out of Scope.

## Full

- Everything applicable from the core template, Options A/B/C when the decision space is real.
- Required when **any one** core escalation trigger fires (core step 2): auth/sessions/tokens, shared contract, persistence/migration, feeds `agon goal`/`conquer`, spans sessions or unclear root cause — regardless of file count.
- Also Full when: new feature module, public API consumed elsewhere, bug with unclear root cause, investigation work.
- Multi-session or codebase-wide → Full spec + satellite docs so each file loads in one session.
- Contract trigger → Contract table + Deploy Order (load `contract-discovery` on demand).
- ≤ ~300 lines; beyond that split into phases or satellites. Full refine (a–g).

- **What Already Works** is required in Full: what does NOT change, and why.

## Anti-patterns

- Staying Surgical after a trigger fired because "it's only 2 files".
- A Full spec for an obvious single-file fix with no trigger — skip the spec (core step 1).
