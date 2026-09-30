# Addon: criteria-test-map

Every acceptance criterion and each of its tricky inputs maps to a test or fixture, every planned test maps back, and the tests are proven to bite. Hooks: core step 6 (mapping), core step 9 (prove the tests).

## When to use

- Default: always when enabled. Presets may narrow it (e.g. only when the spec feeds `agon goal` / `conquer`).
- Forced, whatever the preset says, when the spec touches auth, guest accounts, payment, persistence, deletion or privacy (core step 2): every security or privacy requirement is an AC with a named test.
- Any spec whose acceptance criteria will be implemented as automated tests or oracle fixtures.

## What it adds to the spec

```markdown
## Criteria ↔ Tests
| AC | Tricky input | Test / fixture | Type | Status |
|---|---|---|---|---|
| AC-1 | `de` date at year boundary `31.12.1999` | `format-date.test.ts` › "AC-1 de 31.12.1999" | unit | planned |
| AC-1 | `de-CH` alias of `de` | `format-date.test.ts` › "AC-1 de-CH alias" | unit | planned |
| AC-2 | `null` date | existing `format-date.test.ts` › "null" | unit | exists |
| AC-3 | SSR and client render the same `fr` date | manual: open a `fr` page, compare | manual | — |

Unmapped tests: none.
```

## Rules

- **Forward**: every AC and every one of its `Tricky inputs:` has its own row and a test, fixture, or an explicit `manual:` check with steps. The test name carries the input.
- **Backward**: every planned test names the AC it proves. A test with no AC is either a missing criterion (add it) or scope creep (drop it).
- Test names carry the AC ID (`AC-3` in the test title or describe block) so the link survives refactors.
- Test names are concrete (file + test title or command), not "add tests".
- Status: `planned`, `exists`, `manual`. A tricky input without a row is a gap at step 6.
- A criterion that cannot be tested is not binary — rewrite it.
- Success metrics are not mapped here.

## Eval rows

Prompt, skill or doc artifacts whose acceptance is agent behaviour get an `Eval:` AC and Type `eval`.

- Arms: baseline vs treatment, same model, same prompt; the prompt never names the property under test. `n` runs per arm.
- Rubric: objective per-item pass/fail, saved before any run.
- Outcomes: `PASS` (treatment avoids the flaw in ≥ k of the cases where baseline shows it; k fixed in the rubric), `NO-SIGNAL` (both avoid or both fail; recorded, never PASS, GAP at converge), `FAIL`.
- ≥ 1 false-positive probe: a correct look-alike the treatment must not "fix".
- Run the baseline before the treatment is installed globally; a global or symlinked install contaminates it.

Step 6 check: any AC or tricky input without a row, any test without an AC, any test that would pass on a plausibly wrong implementation?

## Prove the tests (step 9)

A passing test proves nothing until a wrong implementation makes it fail. Use the machine `mutation` setting as the starting rung; unset → first rung that works:

1. **agon** — `agon review --mutate` on the diff, with extra flags from the rules of record. Only with effective agon on.
2. **tool** — the repo's mutation tool if one exists (e.g. Stryker / Stryker.NET, mutmut, PIT, cargo-mutants, go-mutesting — whatever the stack already uses). Scope it to changed files.
3. **subagent** — fresh-context subagent: mutate the changed lines one at a time (flip conditions, off-by-one, drop a call, swap args), run the mapped tests per mutant, report survivors. Restore the tree after.
4. **manual** — flip one condition in the changed code per criterion; the mapped test must fail. Revert.
5. **eval** — for `Eval:` rows: planted-bug fixtures with an answer key kept outside the fixture dir; the treatment must catch each planted bug.

Record the result:

```markdown
## Test strength
Rung: tool (Stryker, `npx stryker run --mutate src/format-date.ts`, 2026-01-31)
Survivors on AC-mapped tests: AC-2 (`'/'` → `'.'` survived) → test sharpened.
```

- **Survivor on a criterion-mapped test = that criterion is not really checked.** Fix the test, or sharpen the criterion so a test can discriminate.
- Survivors on unmapped code are advisory.

## Anti-patterns

- One catch-all test mapped to every AC or every tricky input.
- "Covered by e2e" without naming the test.
- Mapping tests only forward, so extra tests silently widen scope.
- Calling a criterion PASS in converge while a mutant on its test survived.
