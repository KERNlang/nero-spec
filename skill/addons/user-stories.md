# Addon: user-stories

Prioritized user stories, each independently testable. Hook: core step 4, section before Acceptance Criteria.

## When to use

- Default: tier 4 / multi-phase work only. Presets may widen or narrow this.
- The work ships in phases and the team needs to know what can be cut.
- Skip for internal refactors with no user-facing role.

## What it adds to the spec

```markdown
## User Stories

### US-1 [P1] <role> can <capability> so that <outcome>
Independent test: <how this story is verified on its own, without US-2+>
Criteria: AC-1, AC-2

### US-2 [P2] ...
```

## Rules

- **P1** must ship in the first phase; **P2** planned; **P3** nice-to-have, first to cut.
- Every story is **independently testable**: it can be demonstrated with only the P1 stories plus itself.
- Every story lists the Acceptance Criteria it owns; every AC belongs to at least one story.
- Stories order the phases in Phase Tracking (tier 4); they are not a task breakdown.
- Role is a real user or system role, not "developer".

## Anti-patterns

- Stories that only make sense together ("US-2 depends on US-3") — merge or reorder.
- Everything P1.
- Stories as disguised tasks ("As a developer I want to refactor the store").
- Stories without linked criteria.
