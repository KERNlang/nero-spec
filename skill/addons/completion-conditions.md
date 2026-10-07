# Addon: completion-conditions

Hook: core step 8, step 9.

Replaces core `Done when` and `## As-built delta` (step 8, step 9) while loaded.

## When to use

Work built in reviewed slices where progress is reported per AC instead of as one final delta.

## What it adds to the spec

- `## Completion conditions` at approval: gates + ACs.
- Per slice and at the end: each AC met / not met with its check, plus `## What was not done`.
- Plan changes go into the Corrections Log.
- Scope check stays: `git diff --name-only <Verified at>..HEAD` vs `## Changes`.

## Anti-patterns

- An AC marked met without its check.
- A plan change made silently instead of logged in the Corrections Log.
- Omitting `## What was not done` because everything "basically" shipped.
