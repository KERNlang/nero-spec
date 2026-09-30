# Nero vs Spec Kit: paired developer pilot (2026-09-29)
Curated, path-sanitized copy of a private benchmark pilot. Start with [REPORT.md](REPORT.md).

## What was run
- One Go task: typed flag schema introspection for `urfave/cli/v3` at a fixed base commit.
- Same model and effort for both builders (fresh-context, high reasoning); Nero Spec workflow vs Spec Kit workflow.
- A hidden behavioral oracle (`evaluator/eval_schema_test.go`) written before dispatch; RED on base, GREEN on the reference fix.

## Headline results (from REPORT.md)
- Both first passes passed the hidden oracle, builder tests, regressions, build, vet and docs checks.
- Supplementary non-getter probe (outside the preregistered oracle): Nero passed on first pass; Spec Kit first pass panicked in both schema methods and needed one repair round, after which all gates and the probe passed.
- Task wall time to first frozen candidate: Nero 20m33s, Spec Kit 9m01s (includes Nero's external prebuild critique; not compute time).
- Authored spec artifacts: Nero 118 lines in 1 file; Spec Kit 321 lines in 10 files.
- Historical 12-case exercise (bug-detection points out of 36; specs, not implementations):

| Framework | No critic | Subagent critic |
| --- | --- | --- |
| Nero Spec | 23 | 27 |
| Spec Kit | 19 | 23.5 |
| Kiro | 23.5 | 28 |
| OpenSpec | 19.5 | 24.5 |

## Limitations
- n=1 task, one seed. Confidence that this supports a general framework ranking: 0.30.
- A later raw-writer-vs-Nero control (same subagent critic) showed no clear template benefit; the preregistered noise rule fired.
- Nero's workflow includes a required external critic, so the template is not isolated from those calls.
- Token use was not measured; line/byte counts are proxies.

## Contents
`REPORT.md`, `PROTOCOL.md`, `EVALUATION.md`, `EVIDENCE_INDEX.md`, `FRAMEWORK_PINS.md`, `INPUTS.json`, `FLOW_REPORT.json`; `evaluator/` (oracle, probes, gate logs, frozen reports/diffs); `agon/` and `reviews/` (reviewer outputs); `historical/` (score tables, control prereg); `arms/` (authored specs, worklogs and product files extracted from the frozen archives).

## Excluded and why
- Frozen arm archives (`*.tar`, 18-23 MB each) and vendored framework clones/skill copies: size and third-party content. Pins are in `FRAMEWORK_PINS.md`; `arms/` holds only the extracted authored files.
- Generated godoc reference dump (60 KB) and raw agent transcripts.
- Consequently, `EVIDENCE_INDEX.md`, `INPUTS.json` and the reports still cite the excluded tars, `arms/*/.git`, and `frameworks/` paths; those hashes describe the original private archive, not files here.

## Sanitization
- Absolute paths were replaced: `<work>` (temporary workspace), `<bench>` (pilot root), `<spec-bench>`, `<home>` (user home). No report text was reworded.
- `SHA256SUMS.txt` is regenerated for the files published here (the original no longer matches); verify with `shasum -a 256 -c SHA256SUMS.txt`.
