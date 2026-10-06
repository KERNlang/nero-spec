---
name: operator-reviewed
addons: depth-light, refine, drift-guard, criteria-test-map, visual-grid
agon: ask
specs.path: .claude/specs/{slug}/spec.md
branch.pattern: {type}/{slug}
---

# Preset: operator-reviewed

One human operator owns every decision, reviews each slice in the IDE, and approves every commit, push and
public post. Fits frontend product work with thin tickets, Figma layouts and small reviewed PRs. Opt-in: the
overrides below replace the named core.md rules only while this preset is active.

## Overrides of core.md

1. **Purpose and authority** replaces `## Intent` (step 1, step 4):
   ```markdown
   ## Purpose and authority
   <1–3 sentences: what we deliver and for whom.>
   <Which source controls what: ticket = content, design file = layout; a design node marked "in review" is not approval.>
   ### Ticket interpretation        (thin or ambiguous tickets)
   1. <how we read requirement 1, precise and testable>
   2. <what the ticket does NOT ask for → also in Out of Scope>
   **Accepted:** … **Proposed:** … **Open:** …
   ```
   Re-read the original ticket before approval and again before the PR.
2. **Test cases from real data** replace `Tricky inputs` (step 4): cases come only from real data, the ticket, or
   real users (`input · expected result · preview link`). No fixed count, nothing invented. A named hazard is still
   never waived: test it or cite why it cannot happen.
3. **Visual grid** replaces the per-AC `Device check:` (step 4, step 9): every UI change gets one grid —
   desktop + mobile × light + dark — through the `visual-grid` addon, scoped to the touched surfaces.
4. **Completion conditions** replace `Done when` + `## As-built delta` (step 8, step 9): `## Completion conditions`
   at approval (gates + ACs); per slice and at the end, each AC met / not met with its check, plus
   `## What was not done`. Plan changes go into the Corrections Log. Keep the scope check:
   `git diff --name-only <Verified at>..HEAD` vs `## Changes`.
5. **Changed things** replace one `Callers:` line per symbol (step 4) for shared things:
   `| Changed thing | Kind | Scope | Contract change | Used by (count, where) | Tests covering it | Why | Risk / reachable via | Evidence |`
   Kind: function, prop, event, CSS class, token, route, store field, test id. Contract change: none · additive ·
   breaking. *Used by* also searches sibling repos (E2E suites using selectors, CMS templates sharing CSS).
   Evidence = the cited search + count. Internal-only changes stay a short list.
6. **Precedent** replaces `Real usage:` (step 4): reuse candidates go in `## What Already Works`; each option adds
   `Precedent: <where this pattern already exists> (<file>, <size>)` so its size can be compared.
7. **Critic is offered, not forced** (step 8): the operator reviews every decision; that review is the critic
   (`Critic: operator review, YYYY-MM-DD`). Before a larger build, offer one extra critic — `agon nero` when the
   operator granted Agon for this task, else a fresh-context subagent — and run it only on yes.
8. **No length budget, no OPEN cap** (step 5, step 6): depth follows the work. Every decision is the operator's:
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
