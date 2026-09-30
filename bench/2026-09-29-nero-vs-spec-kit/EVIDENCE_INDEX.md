# Pilot evidence index

Status: complete for the registered pilot and one repair round. Paths are relative to this pilot root unless absolute. Confidence: 0.98 for listed frozen identities and receipts.

| Evidence | Path or identity | Purpose |
| --- | --- | --- |
| Preregistered protocol | [PROTOCOL.md](PROTOCOL.md) | Design, clocks, intervention and reporting boundaries |
| Task, base, framework pins, bootstrap receipts | [INPUTS.json](INPUTS.json) | Shared task text and setup provenance |
| Frozen evaluator plan | [EVALUATION.md](EVALUATION.md) | Oracle hash, reference discrimination, identical gates |
| Hidden test source | `evaluator/eval_schema_test.go`; SHA-256 `73ce5be25077b36113a25db5bf25a5bec9adc477f484f52dca4c5f3dd48da845` | Prewritten private behavioral oracle |
| Reference RED/GREEN logs | `evaluator/base-red-v2.log`, `feature-red-v2.log`, `fix-green-v2.log` | Base, original feature, and follow-up fix discrimination |
| Builder worklogs | `arms/nero/.pilot/worklog.md`, `arms/speckit/.pilot/worklog.md` | Native stage and captured time records |
| Spec Kit first-pass report | [evaluator/frozen/speckit-first-report.md](evaluator/frozen/speckit-first-report.md); SHA-256 `0f3dc9b7e1adae633c694e1dadcdf16d0e31256727fc91048c7c858bfea7b472` | Frozen outcome and exact gate commands |
| Nero first-pass report | [evaluator/frozen/nero-first-report.md](evaluator/frozen/nero-first-report.md); SHA-256 `830f5323e4389e09ad3c54be52a7a0784bb4e3474a5ebb465d6e84e7ab4126ae` | Frozen outcome and exact gate commands |
| Nero full archive | `evaluator/frozen/nero-first.tar`; SHA-256 `51ceb7b0da014106f49ca9a68fb1a8c34e5f158f70492c20ec77c08cbd45ca87` | First-pass source, docs, artifacts, and Git state |
| Nero tracked patch | `evaluator/frozen/nero-tracked.diff`; SHA-256 `7acf884c8ef771df3d68e02a7700969ffbd5c25bb0b070f024fd6688a3eaec52` | Tracked changes only |
| Nero status | `evaluator/frozen/nero-status.txt`; SHA-256 `1a01bc4a9dd0492dc4351f891a5734f5f335af117622428171c42e3a82d2b064` | Untracked-file inventory |
| Nero sizes | [evaluator/frozen/nero-sizes.json](evaluator/frozen/nero-sizes.json) | Product, generated docs, authored spec byte counts and hashes |
| Nero raw gates | `evaluator/runs/nero-*.log` and corresponding `.exit` files | Hidden oracle, builder tests, regressions, build, vet, docs |
| Spec Kit full archive | `evaluator/frozen/speckit-first.tar`; SHA-256 `79bb17fce05f3fa65081e927f50d4239530c523113204ab7069cdf219e15d75e` | First-pass source, docs, artifacts, and Git state |
| Spec Kit tracked patch | `evaluator/frozen/speckit-tracked.diff`; SHA-256 `fc7b61c9a7ea7b5a95ee2afe91fd83c09df9727e3ada0ca3d5e5c804795fb9c4` | Tracked changes only |
| Spec Kit status | `evaluator/frozen/speckit-status.txt`; SHA-256 `9c8ec4f51ef4354b49c8832f07c1726a587c2521ae697090e3f37a454872dde2` | Untracked-file inventory |
| Spec Kit sizes | [evaluator/frozen/speckit-sizes.json](evaluator/frozen/speckit-sizes.json) | Product, generated docs, authored-artifact byte counts and hashes |
| Spec Kit raw gates | `evaluator/runs/speckit-*.log` and corresponding `.exit` files | Hidden oracle, builder tests, regressions, build, vet, docs |
| Spec Kit repair archive | `evaluator/frozen/speckit-repair.tar`; SHA-256 `a3d8201795c3b8beb1930d4075ecec7f4e20b0e00ecb8e128ffc68f3c55f0f6e` | Correction candidate frozen at 17:35:45 UTC; repeated gates passed |
| Historical 12-case scores | `historical/bench6/score6_out.txt` | Detection points out of 36 |
| Historical control | `historical/bench6/control/PREREG.md`, `scoreC_out.txt` | Paired raw/Nero critic control and noise rule |
| Nero mutation probe | `agon/nero-mutation` | AI-proposed-bug prebuild critique; no Go code mutants executed |
| Nero tribunal | `agon/nero-tribunal` | Three requested seat outputs; extra Kimi synthesis excluded |
| Spec Kit independent review | `agon/speckit-review` | Completed raw three-seat outputs; shared non-getter finding reproduced separately |
| Spec Kit supplementary review test | `evaluator/runs/speckit-review-ext-nogetter-red.log`; SHA-256 `ff305fc789cc92fafcf5e99b01fec377c2760a68641ab0ee1a1f2d194086c3df` | Separate postreview RED reproduction of both non-getter panics; test source SHA-256 `2cf5ba545e61540c3c8088b85cc6ed7b25c3f20d0f8ec9ff05b47d2ef4c63b26` |
| Nero supplementary review test | `evaluator/runs/nero-review-ext-nogetter.log`; SHA-256 `a182460ecec4633aae701c8e714d1572ba7cdc332e0feb1977d61aaaa4903ae3`; same test source SHA-256 `2cf5ba545e61540c3c8088b85cc6ed7b25c3f20d0f8ec9ff05b47d2ef4c63b26` | Separate postreview GREEN result for both schema methods |
| Supplementary probe reports | `evaluator/runs/NERO_POST_REVIEW.md`, `evaluator/runs/SPECKIT_POST_REVIEW.md` | Scope and exact commands of the non-getter probe |
| Nero independent review | `agon/nero-review` | Completed three-seat source review; no raw blocker |
| Spec Kit repair report | [evaluator/frozen/speckit-repair-report.md](evaluator/frozen/speckit-repair-report.md); SHA-256 `03d1bec064998cca5fccc37f1c827715eef17d1b23189a6c3bb01a4a52b98862` | Frozen postfeedback result; all repeated gates and non-getter probe pass |
| Spec Kit repair confirmation | [agon/speckit-repair-confirmation/claude-output.txt](agon/speckit-repair-confirmation/claude-output.txt), [status.json](agon/speckit-repair-confirmation/status.json) | Targeted source review, one Claude seat, exit 0, no blocker |
| TextVar exploratory probe | `evaluator/review_textvar_time_test.go`; SHA-256 `6363feceafb9a0b0df14fe4116aec6a582f10390e782fd2718ca5f1b6f5b239f`; three `evaluator/runs/*-textvar-time.log` files | Shared pointer mapping observation, outside registered scoring |
| Framework pins | [FRAMEWORK_PINS.md](FRAMEWORK_PINS.md), [INPUTS.json](INPUTS.json), `frameworks/nero/skill` | Pinned native source and relocation note |
| Flow report | [FLOW_REPORT.json](FLOW_REPORT.json) | Orchestration logging receipt |
| Archive integrity | [SHA256SUMS.txt](SHA256SUMS.txt) | Hash of every copied regular file except this manifest |

The frozen tar files contain full arm snapshots; evaluator run directories and review mirrors were intentionally omitted because the relevant tests, logs, patches, and receipts are copied here. Original source roots are `<work>`, `<home>/.agon/runs`, and `<spec-bench>/bench6`. No historical detection point is a developer-pilot outcome. The original Nero repository is outside both builder arms.
