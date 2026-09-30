# Addon: tier-1-surgical

Tier 1 — Surgical Fix. Hook: core step 2 (depth); any core escalation trigger forces tier 2+.

## When to use

- Single-file or few-line change with clear root cause.
- Size: < 100 lines.
- Examples: A date formatting bug, a wrong enum mapping, a missing null check. The patterns below apply to any small, scoped fix -- adapt the examples to your domain.

---

## What it adds to the spec

Required sections:

| Section              | Purpose                                          |
| -------------------- | ------------------------------------------------ |
| Executive Summary    | 2-3 sentences: what is wrong, how big is the fix |
| Root Cause           | Code-level analysis with file paths + symbols    |
| What Already Works   | Prevent over-engineering -- list what NOT to fix  |
| Implementation Plan  | 1 plan is OK (no A/B/C needed for surgical)      |
| Changes              | `ADDED/MODIFIED/REMOVED:` lines (core step 4)     |
| Verified Counts      | Every number backed by a command                  |
| Acceptance Criteria  | Binary pass/fail table                           |

**Optional:** Decision Points, Out of Scope, Risks.

---

## Pattern: Executive Summary

State the scope and size of the fix upfront. Name the file and function.

```markdown
## Executive Summary

The `formatDate` utility renders `en-US` dates correctly but applies the
same `MM/DD/YYYY` order to `de` and `fr`. **2 of 3 locale configs use the
wrong day/month order.** This is a 2-line fix in the locale config constant
+ test coverage expansion.
```

**Why this works:** Reader knows within 3 sentences that this is a small fix, not a redesign.

---

## Pattern: Root Cause with Discrepancy Table

Show current vs required state in a table. Mark each row with a pass/fail indicator.

```markdown
## Root Cause Analysis

### Current State (`format-date.ts:8-14`)

| Locale  | Current Output | Required Output | Impact                          |
| ------- | -------------- | --------------- | ------------------------------- |
| `en-US` | `03/04/2026`   | `03/04/2026`    | Correct                         |
| `de`    | `03/04/2026`   | `04.03.2026`    | Day/month swapped for DE users  |
| `fr`    | `03/04/2026`   | `04/03/2026`    | Day/month swapped for FR users  |
```

**Why this works:** Discrepancies are immediately visible. The "Impact" column justifies the fix.

---

## Pattern: What Already Works

Prevents over-engineering by listing what does NOT need changing and why.

```markdown
### What Already Works

- Timezone conversion -- done upstream in `toLocalTime`, locale-independent
- Relative dates ("2 days ago") -- separate formatter, already localized
- Server-side rendering -- `formatDate` runs on server, no hydration mismatch
- Invalid date handling -- already tested, renders an em dash
```

**Why this works:** Stops the implementer from "fixing" things that work. Each point explains WHY it is safe.

---

## Pattern: Verified Counts

Every number must include the command that produced it. No bare assertions.

```markdown
### E2E Test Impact: ZERO BREAKAGE

Verified that no E2E tests assert on formatted dates:

(`grep -rn '03/04/2026' tests/e2e/` -- 0 matches, 2026-01-31)

3 unit tests in `format-date.test.ts` cover `en-US` only
(`grep -c 'formatDate' src/utils/format-date.test.ts` -- 3)
```

**Why this works:** Reviewers can re-run the command to verify the claim. Counts do not go stale silently.

---

## Pattern: Changes

Small, precise. One line per file.

```markdown
## Changes
MODIFIED: `src/utils/format-date.ts` — de/fr locale config
MODIFIED: `src/utils/format-date.test.ts` — cases for all 3 locales
```

---

## Pattern: Acceptance Criteria Table

Binary pass/fail. Each criterion names ≥ 1 concrete tricky input and a verification method.

```markdown
## Acceptance Criteria

| #    | Criterion                            | Tricky inputs               | How to Verify                  |
| ---- | ------------------------------------ | --------------------------- | ------------------------------ |
| AC-1 | DE locale renders `DD.MM.YYYY`       | `31.12.1999`, `de-CH` alias | Unit test for `de` locale      |
| AC-2 | FR locale renders `DD/MM/YYYY`       | `01/02/2000` (day ≠ month)  | Unit test for `fr` locale      |
| AC-3 | en-US unchanged                      | `null` date                 | Existing test passes unchanged |
| AC-4 | Server-rendered dates match client   | SSR at UTC midnight         | Manual check on a `fr` page    |
```

---

## Anti-patterns for Tier 1

- **Do not** add implementation options A/B/C for a 2-line fix
- **Do not** write a change dependency matrix for a single file
- **Do not** add a corrections log unless you actually corrected a wrong claim
- **Do not** skip "What Already Works" -- this is what prevents scope creep
