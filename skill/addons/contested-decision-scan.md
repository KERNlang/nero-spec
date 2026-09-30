# Addon: contested-decision-scan

Experimental. Off by default in every preset; enable per repo with `addons: +contested-decision-scan` in `.spec`.

Surface behaviour choices that have more than one defensible reading and turn them into tests, without settling them by opinion. Hook: core step 4, after reading the task and the code, before drafting.

## When to use

- Changes to shared behaviour other code relies on: accepted input, output or state shape, call order or lifecycle, error and degenerate-case handling, strictness, or which existing behaviour to keep.
- Depth: **Surgical** — top 1 decision, record line only. **Full** — top 2.
- Skip for pure additions nothing else calls yet, and for exact-value fixes.

## What it adds to the spec

- Tricky inputs with named tests for each reading's Breaks scenario.
- One `Contested:` line per decision under Implementation Options. No decision found → nothing is added; the scan leaves no trace.

## Scan

List decisions where at least 2 readings are each defensible AND a caller, consumer, dependent library or the runtime behaves differently depending on which one ships. Keep the top decisions by blast radius (see depth above). Per decision record the readings, the evidence in hand, and what **Breaks** under each reading.

## Resolve

The scan names the fork; it never settles it. Per decision:

1. **Breaks → tests.** Each reading's Breaks scenario becomes a Tricky input with a named test, whichever reading ships. The test asserts the scenario works; a scenario the pick gives up (step 3) is instead pinned to its documented failure, named as an accepted loss.
2. **Consumers settle it.** Only evidence from real consumers or callers settles a decision (core step 4 `Real usage`): call sites, dependent modules, tests that exercise the path, documented contracts, known external dependents. Task wording, cleanliness or strictness are not evidence. Cite the paths.
3. **Unsettled → conservative pick.** No settling evidence → the decision is OPEN and ships the reading that keeps both Breaks scenarios working; when none can, the less restrictive one (accepts more input, blocks less, keeps existing behaviour), naming the Breaks scenario it gives up.

## Record

`Contested: <decision> — Picked: <reading> · Not this: <reading> · Evidence: <consumer cites | none> · Status: VERIFIED | OPEN | ASSUMED`

- VERIFIED only when a cited consumer or caller requires the picked reading.
- OPEN lines count toward the OPEN cap (core step 5). When the cap or `refine` step f forces one to ASSUMED, the tag changes but the picked reading does not: it stays the conservative pick unless new consumer evidence is cited.

## Anti-patterns

- Picking the stricter or more literal reading because the code or task "reads that way".
- A critic finding alone flipping a Contested pick to the stricter reading.
- Listing a decision whose readings no caller would notice.
