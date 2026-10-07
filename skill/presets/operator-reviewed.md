---
name: operator-reviewed
addons: depth-light, refine, drift-guard, criteria-test-map, visual-grid, ticket-interpretation, changed-things, completion-conditions
agon: ask
specs.path: .claude/specs/{slug}/spec.md
branch.pattern: {type}/{slug}
---

# Preset: operator-reviewed

One human operator owns every decision, reviews each slice in the IDE, and approves every commit, push and
public post. Fits frontend product work with thin tickets, Figma layouts and small reviewed PRs. Opt-in: the
overrides below and the addons above replace the named core.md rules only while this preset is active.

## Overrides of core.md

Carried by addons: `ticket-interpretation` (Intent), `visual-grid` (Device check), `completion-conditions` (Done when / As-built delta), `changed-things` (Callers, Real usage).

1. **Test cases from real data** replace `Tricky inputs` (step 4): cases come only from real data, the ticket, or
   real users (`input · expected result · preview link`). No fixed count, nothing invented. A named hazard is still
   never waived: test it or cite why it cannot happen.
2. **Critic is offered, not forced** (step 8): the operator reviews every decision; that review is the critic
   (`Critic: operator review, YYYY-MM-DD`). Before a larger build, offer one extra critic — `agon nero` when the
   operator granted Agon for this task, else a fresh-context subagent — and run it only on yes.
3. **No length budget, no OPEN cap** (step 5, step 6): depth follows the work. Every decision is the operator's:
   big ones one at a time (concept, options table, recommendation, one question); small ones as one list of
   proposed defaults, tagged ASSUMED until confirmed.

## Header

```markdown
# [Title]
**Date:** YYYY-MM-DD
**Depth:** <Surgical | Full>
**Verified at:** <git rev-parse --short HEAD>
**Status:** SPEC | READY TO BUILD | IN PROGRESS | DONE — slices <x> of <n> done, now <n> (<name>). Implementation authorized for <slices | spec only>.
```

The enum keeps `spec-check.sh` happy; the note carries the slice counter and the authorization. Update it in
the same edit as the task list. Never write code beyond what the Status authorizes.

## Constitution

- Rules of record: machine `rules` file (core.md defaults when unset); the overrides above win.
- Slices: one review concern each; leave changes unstaged for the operator's IDE review; commit only what the
  operator staged, with the operator's wording. No AI trailers.
- Nothing becomes public (PR text, review comments, tickets, chat) unless the operator approves it.
- Effective agon on → only after the operator grants it for this task; off → fresh-context subagent.
- Feature branch + PR; never push main/master or shared branches.

## Risk notes

- Thin tickets hide the real scope: the Ticket interpretation list is where most scope creep is caught.
- Reviewers flag what the spec skipped: domain contracts, missing "why" comments on workarounds, reuse of an
  existing helper, untested branches, hover and dark mode.
