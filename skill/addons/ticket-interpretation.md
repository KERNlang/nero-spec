# Addon: ticket-interpretation

Hook: core step 1, step 4, step 8.

Replaces core `## Intent` (step 1, step 4) while loaded.

## When to use

Thin or ambiguous tickets where the ticket text and the design or other sources must be reconciled before building. Skip when the ticket is precise.

## What it adds to the spec

```markdown
## Purpose and authority
<1–3 sentences: what we deliver and for whom.>
<Which source controls what: ticket = content, design file = layout; a design node marked "in review" is not approval.>
### Ticket interpretation        (thin or ambiguous tickets)
1. <how we read requirement 1, precise and testable>
2. <what the ticket does NOT ask for → also in Out of Scope>
**Accepted:** … **Proposed:** … **Open:** …
```

## Required patterns

- Re-read the original ticket before approval (step 8) and again before the PR.
- Every "does NOT ask for" line also appears in Out of Scope.

## Anti-patterns

- Treating a design node marked "in review" as approval.
- Interpretation lines that cannot become a test.
- Reading the ticket once at the start and never again.
