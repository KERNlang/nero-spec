# Addon: tier-4-migration

Tier 4 — Migration / Large-Scale. Hook: core step 2 (depth); any core escalation trigger forces tier 2+.

## When to use

- Codebase-wide changes, multi-session work, high blast radius.
- Size: Split into `spec.md` (overview) + satellite docs (loaded on demand).
- Examples: A CSS framework upgrade, a major library migration, a monorepo restructure. The patterns below apply to any large-scale migration -- library upgrades, framework changes, or codebase-wide refactors. Adapt the examples to your domain.

---

## What it adds to the spec

Required sections:

| Section               | Purpose                                                    |
| --------------------- | ---------------------------------------------------------- |
| Executive Summary     | Migration scope, risk level, timeline estimate             |
| Root Cause            | Why the migration is needed, what breaks without it        |
| Implementation Options | A/B/C plans with blast radius + trade-offs                |
| Changes               | `ADDED/MODIFIED/REMOVED:` lines, grouped by phase          |
| User Flow Impact      | All affected flows, marked changed vs unchanged            |
| Acceptance Criteria   | Binary pass/fail                                           |
| Decision Points       | Trade-offs that need human judgment                        |
| Out of Scope          | Explicit exclusions                                        |
| Change Dependency Matrix | Which changes must be co-applied                        |
| Refine                | `## Refine` block (`refine` addon), one per phase gate      |
| Phase Tracking        | Progress table as the single source of truth               |
| Verification Spec     | Separate doc -- self-contained for new sessions            |
| Context Budget        | Declare what to load per session                           |

**Recommended:** Infrastructure reference, corrections log, polish log.

---

## Pattern: Phase Tracking Table

The progress table IS the spec for any session joining mid-migration.

```markdown
## Phase Tracking

| Phase | Description         | Status      | Files | Notes                        |
| ----- | ------------------- | ----------- | ----- | ---------------------------- |
| 1     | Config + build      | DONE        | 3     | Clean build verified         |
| 2     | Syntax migration    | DONE        | 127   | Automated via codemod        |
| 3     | Verification        | IN PROGRESS | 0     | 3/5 regressions found        |
| 4     | CI + visual tests   | NOT STARTED | ~5    | Blocked on Phase 3           |
| 5     | Polish              | NOT STARTED | TBD   | Deferred debt from Phase 2   |
```

**Why this works:** Any session can read this table and know exactly where to pick up.

---

## Pattern: Session Handoff Protocol

New sessions should NOT read the full spec. Write a verification doc that stands alone.

```markdown
## Session Handoff

**New sessions: read `<spec folder>/verification.md` ONLY.**
This file contains everything needed to continue Phase 3.
Do NOT read the full spec unless investigating root cause of a regression.

### What the verification doc contains:
- Current phase + what's done
- Exact commands to run
- Known regressions and their status
- Environment setup (build, server, ports)
```

**Why this works:** Prevents context rot. A 500-line spec loaded into a new session wastes 40% of context on history that doesn't help the current phase.

---

## Pattern: Infrastructure Reference

Self-contained commands section. No hunting through the codebase for setup instructions.

```markdown
## Infrastructure Reference

### Build & Verify
<clean command> && <build command>   # Clean build -- cached output may miss changes
<start command>                      # Port, mock/real backends

### Test Commands
<full suite command, sharded if slow>
<targeted command for the affected area>

### Known Gotchas
- Incremental builds may reuse cached output -- clean first
- Restart dev servers after a rebuild to pick up new artifacts
- Note local vs CI test timeouts when multi-step tests flake
```

**Why this works:** Saves 5-10 minutes per session of "how do I run this again?" Gotchas prevent repeating known traps.

---

## Pattern: Context Budget Declaration

Explicitly state what each session type should load.

```markdown
## Context Budget

| Session type        | Load                          | Do NOT load              |
| ------------------- | ----------------------------- | ------------------------ |
| New verification    | `verification.md` only        | Full spec, phase 1 notes |
| Regression analysis | `verification.md` + this spec | Phase 1-2 execution logs |
| Polish phase        | `polish-log.md` only          | Everything else          |

### Related Specs
| Doc                        | When to read                    |
| -------------------------- | ------------------------------- |
| `spec.md`                  | Only if investigating root cause |
| `verification.md`          | Every verification session       |
| `polish-log.md`            | Polish phase only                |
```

**Why this works:** Keeps sessions focused. Loading 3 docs into context is wasteful when 1 suffices.

---

## Pattern: Satellite Doc Structure

Split large specs into overview + on-demand satellite docs.

```markdown
<specs.path folder>/        # e.g. PROJ-123-tailwind-v4 or tailwind-v4
├── spec.md              # Overview: phases, decisions, blast radius (~200 lines)
├── verification.md      # Self-contained: current phase, commands, regressions
├── polish-log.md        # Deferred debt from migration phases
└── phase-2-details.md   # Only loaded if Phase 2 needs revisiting
```

Rule: No single file exceeds 20K tokens. If it does, split.

---

## Anti-patterns for Tier 4

- **Do not** keep everything in one file past 20K tokens -- split into satellite docs
- **Do not** leave the phase tracking table stale -- update it every session
- **Do not** load the full spec into new verification sessions -- use the handoff doc
- **Do not** skip the infrastructure reference -- it prevents "works on my machine" waste
- **Do not** defer broken output to "polish" -- broken = bug, fix now (debt = cosmetic, defer)

