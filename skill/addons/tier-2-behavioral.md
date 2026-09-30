# Addon: tier-2-behavioral

Tier 2 — Bug Fix / Behavioral Change. Hook: core step 2 (depth); any core escalation trigger forces tier 2+.

## When to use

- Multiple files, behavioral change, user-facing impact.
- Size: 100-500 lines.
- Examples: A button showing the wrong state, a form submitting with stale data, a filter not updating the URL. The patterns below apply to any multi-file behavioral change -- adapt the examples to your domain.

---

## What it adds to the spec

Required sections:

| Section                  | Purpose                                                |
| ------------------------ | ------------------------------------------------------ |
| Executive Summary        | What is broken, who is affected, scope of fix          |
| Root Cause               | Code-level (path + symbol), explain WHY it breaks      |
| What Already Works       | Prevent over-engineering                               |
| Implementation Options   | A/B/C plans with blast radius + trade-offs             |
| Changes                  | `ADDED/MODIFIED/REMOVED:` lines + `Callers:` sweep, incl. files receiving different runtime props |
| User Flow Impact         | Enumerate all affected flows, mark changed vs unchanged |
| Acceptance Criteria      | Binary pass/fail                                       |
| Change Dependency Matrix | Which changes must be applied together                 |
| Out of Scope             | Explicit exclusions                                    |
| Decision Points          | Trade-offs that need human judgment                    |
| Refine                   | `## Refine` block from the `refine` addon (replaces a separate self-audit section) |

**Recommended:** "Files NOT affected" analysis, page type impact. **Optional:** one truth table (inputs × before/after, changed row marked) when a boolean condition changes.

---

## Pattern: Change Dependency Matrix

When multiple changes exist, document which must be applied together.

```markdown
### Changes 1+2+3 MUST be applied together

| Applied alone         | Result                                                    |
| --------------------- | --------------------------------------------------------- |
| Change 2 only         | **CRASH.** Publish hook expects `approverId` -> undefined   |
| Change 1 only         | No visible effect -- button still shows wrong label         |
| Change 3 only         | Audit event fires with wrong `doc_action` value             |
| Changes 1+2 without 3 | Button works but audit log shows "request_approval" event   |
| Changes 1+2+3         | Correct. Button, publish logic, and audit all consistent.   |

Change 4 (loading state animation) is independent and can be applied separately.
```

**Why this works:** Prevents partial application that causes crashes. Reviewers know the atomic unit.

---

## Pattern: User Flow Verification

Enumerate every flow that touches the changed code. Mark each as changed or unchanged.

```markdown
## User Flow Impact (10 flows)

| # | Flow                                        | Before              | After                    | Changed?          |
|---|---------------------------------------------|----------------------|--------------------------|-------------------|
| 1 | Editor (editable, no approval) -> Publish   | "Request Approval"   | **"Publish"**            | **YES (the fix)** |
| 2 | Editor (editable, approval) -> Request       | "Request Approval"   | "Request Approval"       | NO                |
| 3 | Viewer (read only)                          | "Read only"          | "Read only"              | NO                |
| 4 | List view -> Quick Publish (no approval)    | "Request Approval"   | **"Publish"**            | **YES (the fix)** |
| ...                                                                                                               |
| 10| Publish -> Notification -> Activity feed    | --                   | Feed entry correct       | NO                |

Flows 1, 4, 7 are fixed. All others unchanged. No regressions.
```

**Why this works:** Exhaustive. If a flow is missing, the spec is incomplete. "NO" rows prove no regression.

---

## Pattern: Files NOT Affected

Explicitly state what does NOT change and why. Prevents "what about X?" questions.

```markdown
### Files NOT affected

| File                        | Why not affected                                  |
| --------------------------- | ------------------------------------------------- |
| `notification-panel.tsx`         | Receives events via context -- no prop change     |
| `activity-feed.tsx`              | Reads from event store, not from button component |
| Comment components               | Completely separate action flow                   |
| API routes (`/api/v1/documents`) | No server-side changes needed                     |
```

---

## Anti-patterns for Tier 2

- **Do not** assume "only 1 file changed = no cascading effects" -- check runtime consumers
- **Do not** skip refine -- it catches more issues than post-build review
- **Do not** list files as "NOT affected" without explaining why
- **Do not** skip user flow verification for user-facing changes

