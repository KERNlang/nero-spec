# Addon: agon-oracle

Turn acceptance criteria into oracle fixtures for `agon goal` / `agon conquer`. Hook: core step 8.

## When to use

- The spec feeds an `agon goal` or `agon conquer` launch.
- Only when effective agon is on (SKILL.md Step 0). Otherwise this addon is not loaded.

## Before anything

- Machine `oracle_rules` set → read it first; its oracle design gate and pipeline are mandatory and override this file where they overlap. If it already defines holdouts or fixture types, follow it.
- Unset → the rules below are the whole gate.

## What it adds to the spec

```markdown
## Oracle
Gate: `<canonical project test command>`
| Fixture | From AC | Type | Holdout | Discriminates against | RED at base? |
|---|---|---|---|---|---|
| `atan2(3, 4) ≈ 0.6435` | AC-2 | example | no | `atan2(y, y)`, swapped args | yes — function missing, 2026-01-31 |
| `atan2(-3, -4) ≈ -2.4981` | AC-2 | example | yes | quadrant-blind impl | yes, 2026-01-31 |
| ∀ x,y≠0, including x<0: `(sin θ, cos θ) ≈ (y/r, x/r)`, where `θ=atan2(y,x)`, `r=hypot(x,y)` | AC-2 | property | no | quadrant-blind sign/ratio shortcuts | yes, 2026-01-31 |

Accepted risks: none.
```

## Rules

- **Fixtures derive from Acceptance Criteria** — one or more per AC; nothing in the oracle without an AC.
- **Type** — `example` (fixed input → output) or `property` (invariant over generated inputs). Prefer at least one property where an invariant exists.
- **Holdout** — at least one `Holdout: yes` fixture per P1 criterion (every AC when there are no user stories). The implementing engine never sees holdouts: keep them out of the prompt, the goal description and the visible verify; run them only in the final check. Defends against building to the test.
- **Promotion rule: no ASSUMED or OPEN claim feeds a final oracle fixture.** Resolve it to VERIFIED first, or record explicit risk acceptance: "accepted risk: X unverified because Y".
- Each fixture names the plausibly-wrong implementation it rejects.
- **Red-team the oracle** before launch: ask one engine for a subtly-wrong implementation that passes the visible fixtures; if it can, add a killer fixture and repeat.
- RED at base for the right reason, gate green at base — record the command and date.
- The gate is the project's canonical test command, not a hand-picked subset. A gate that reads build output builds first.
- Success metrics never become fixtures.
- Repo `agon: restricted` → launch with only `agon_engines`; report any shortfall.

## Anti-patterns

- A fixture that a shortcut implementation passes (`atan2(0, 1)`).
- Holdouts pasted into the goal prompt "for context".
- An ASSUMED field name silently baked into a fixture.
- Narrow gate green while the full suite is red.
- Launching before the oracle was red-teamed.
