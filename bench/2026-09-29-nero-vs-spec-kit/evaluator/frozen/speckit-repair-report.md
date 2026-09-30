# Spec Kit repair round: cli-01

Parent authorized a single feedback repair round after the immutable first pass. The builder froze the repaired arm at 2026-09-29T17:35:45Z; evaluator observed it at 17:36:51Z and archived it at 17:37:00Z. The original `speckit-first.tar`, first-pass report, oracle, and its RED supplementary probe remain unchanged. All checks here ran on `evaluator/runs/speckit-repair`, a new private copy; the arm was not edited.

## Repair snapshot and delta

- Arm HEAD remains base `84d0da5c2dea82f19c9bce4bdf255ee1091231fa` with uncommitted product changes.
- Complete repaired archive: `speckit-repair.tar`, SHA-256 `a3d8201795c3b8beb1930d4075ecec7f4e20b0e00ecb8e128ffc68f3c55f0f6e`.
- Tracked patch from base: `speckit-repair-tracked.diff`, SHA-256 `d512b67f3723369a7fe3e04685edebcf3dce7c4eca5d8f4401e01417324123a9`; status receipt SHA-256 `20b1c33dfad366c6976ad670b508f993708d151aab3eb50164ea1e0691e515fe`.
- Both generated docs snapshots SHA-256 `52fd38ec4e956ffe9d0533cf572ffd1a6ba5e4189302ab83588df2a349fb52ae`.
- Repair-only source patch from frozen first pass: `../review/speckit-repair-only.diff`, SHA-256 `5e189a4b11de8ec0db819484a7d9fbec0ffd161d2f054e05b7076df7f5938024`. It changes only `flag.go`, `flag_ext.go`, and `flag_schema_type_test.go` (11 additions, 1 deletion). The review mirror `../review/speckit-repair-product` has a synthetic local HEAD commit of frozen first-pass product source and this repair as its only working diff. Neither mirror nor patch includes installed framework files, generated docs, or hidden evaluator tests.

## Repeated gates

All Go commands used `GOMAXPROCS=2` and Go `1.26.3 darwin/arm64`. The builder's original focused command, unchanged hidden oracle (`73ce5be25077b36113a25db5bf25a5bec9adc477f484f52dca4c5f3dd48da845`), common six regressions, `go build ./...`, and `go vet .` each exited 0. Exact logs and `.exit` receipts are under `../runs/speckit-repair-{own-test,oracle,common-regressions,build,vet}`. `go doc -all "$PWD"` exited 0, and byte comparisons with both docs snapshots exited 0; generated output and receipts are under `../runs/speckit-repair-godoc*`. No full suite ran.

The unchanged supplementary `TestReviewExternalNonGetter` probe (`2cf5ba545e61540c3c8088b85cc6ed7b25c3f20d0f8ec9ff05b47d2ef4c63b26`) exited 0 at 2026-09-29T17:38:16Z, with both schema methods passing on a standard-library `FlagSet.Func`. The same probe was RED on the original Spec Kit first pass. This is a repair result after feedback, not an unseen first-pass score.

The repair guards `extFlag` schema introspection when the wrapped value lacks `flag.Getter`, adds `flag.Func` to the candidate's external-flag tests, clarifies public interface documentation, and regenerates both doc snapshots. Byte counts in `speckit-repair-sizes.json`: product Go files total 33,006 bytes (net +7,145 from base, +394 from first pass); generated docs total 116,650 bytes (net +1,368 from base, +410 from first pass); authored Spec Kit artifacts remain 12,907 bytes. Installed framework infrastructure and logs are excluded. Sizes are descriptive, not correctness scores.

Independent targeted review is still pending. Confidence: 0.98.
