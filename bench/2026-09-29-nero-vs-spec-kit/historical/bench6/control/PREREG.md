# bench6 control experiment — pre-registration

Written 2026-09-29, BEFORE any spec in this experiment was generated. Not to be edited after generation starts.

Question: does Nero Spec's structure add bug catches beyond the subagent critic?
Design: 12 bench6 cases x 2 arms (RAW, NERO) x 2 seeds (independent re-runs) = 48 final specs.
- RAW = plain opus writer (task statement + worktree + one-line instruction + benchmark access rules) -> bench6 subagent critic -> bench6 revise prompt minus Nero-specific refine steps.
- NERO = Nero Spec writer (snapshot f00de67 = bench6/framework-docs/nero-skill, verified byte-identical) -> same critic -> bench6 nero_sub revise prompt.
Graders: kimi-for-coding-k3, zai-coding-plan-glm-5.3 (agon), blind, one spec per call, bench6 rubric. Catch is 0-3 per case, /36 per arm-seed.

## Decision rules (verbatim)

- Raw+critic avg catch ≥ 26/36, or Nero paired margin ≤ 1.0 catch → structure adds nothing on recall.
- Nero margin ≥ 2.5 catch in BOTH seeds → structure pays off.
- Within-arm seed-to-seed difference > 2.0 catch → benchmark too noisy to decide.
- Otherwise → inconclusive.

## Operational definitions (fixed before data)

- Catch for one spec = mean of the two graders' catch scores. Arm-seed catch = sum over 12 cases (/36).
- "Raw+critic avg catch" = mean of RAW seed1 and RAW seed2 arm-seed catch.
- Nero paired margin for a seed = NERO arm-seed catch − RAW arm-seed catch (same seed index; per-case pairing, summed). Rule 1's "Nero paired margin" = mean of the two seed margins; rule 2 requires each seed margin ≥ 2.5.
- Within-arm seed-to-seed difference = |seed1 − seed2| arm-seed catch, evaluated per arm; > 2.0 in either arm fires rule 3.
- All four rules are evaluated and reported. If rule 3 fires together with rule 1 or 2, the verdict is reported as that rule qualified by "benchmark too noisy"; rule 4 applies only when none of 1-3 fire.
- A spec whose grade is missing after one retry is excluded from both arms for that case/seed pair (logged).
