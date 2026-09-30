# Nero first pass: cli-01

Candidate freeze authorized by parent at 2026-09-29T17:32:16Z. Evaluator observed the arm at 17:33:24Z and archived it at 17:33:35Z. Builder edits had stopped. This report records the first pass before any feedback or repair. No source was changed in the arm; all checks used `evaluator/runs/nero-first` extracted from the frozen archive. Test lease was released after the checks.

## Snapshot identity

- Base and arm HEAD: `84d0da5c2dea82f19c9bce4bdf255ee1091231fa`.
- Full arm archive, including untracked source, docs, Nero link, `.spec`, and `.git`: `nero-first.tar`, SHA-256 `51ceb7b0da014106f49ca9a68fb1a8c34e5f158f70492c20ec77c08cbd45ca87`.
- Tracked patch: `nero-tracked.diff`, SHA-256 `7acf884c8ef771df3d68e02a7700969ffbd5c25bb0b070f024fd6688a3eaec52`. Untracked files are captured in the archive and `nero-status.txt` (SHA-256 `1a01bc4a9dd0492dc4351f891a5734f5f335af117622428171c42e3a82d2b064`).
- `godoc-current.txt` and `testdata/godoc-v3.x.txt` both SHA-256 `ffad9803bdfb02d6413123e24eaee7c90f4bdca633e409ada4780d221f55f05e`; hash receipt in `nero-doc-hashes.txt`.
- Hidden oracle copied into private run snapshot only, SHA-256 `73ce5be25077b36113a25db5bf25a5bec9adc477f484f52dca4c5f3dd48da845`.
- Go version: `go1.26.3 darwin/arm64`. `GOMAXPROCS=2` was used for all Go commands.

## Gates

| Check | Exact command or comparison | Exit | Evidence |
| --- | --- | ---: | --- |
| Builder's focused tests | `GOMAXPROCS=2 go test -run '^TestSchemaType' .` | 0 | `../runs/nero-own-test.log`, `.exit` |
| Frozen hidden oracle | `GOMAXPROCS=2 go test ./ -run '^TestEval' -count=1 -v` | 0 | `../runs/nero-oracle.log`, `.exit` |
| Common six regressions | `GOMAXPROCS=2 go test ./ -run '^(TestBoolWithInverseBasic|TestGenericFlagApply_SetsAllNames|TestIntFlagExt|TestUintFlagExt|TestStringSliceFlagApply_SetsAllNames|TestDocGetValue)$' -count=1 -v` | 0 | `../runs/nero-common-regressions.log`, `.exit` |
| Compile | `GOMAXPROCS=2 go build ./...` | 0 | `../runs/nero-build.log`, `.exit` |
| Vet | `GOMAXPROCS=2 go vet .` | 0 | `../runs/nero-vet.log`, `.exit` |
| Docs generation | `GOMAXPROCS=2 go doc -all "$PWD"` to private output | 0 | `../runs/nero-godoc-generated.txt`, `.exit` |
| Current docs match | `cmp -s` generated output against `godoc-current.txt` | 0 | `../runs/nero-godoc-current-compare.exit` |
| Promoted docs match | `cmp -s` generated output against `testdata/godoc-v3.x.txt` | 0 | `../runs/nero-godoc-promoted-compare.exit` |

The hidden nil `GenericFlag.SchemaItemsType` case passed. The common regression run had two existing `TestIntFlagExt` base-16 subtests skipped by that test's own condition; the command exited 0. No full suite ran.

## Deliverables and size

The six requested product Go files are present or changed: `flag.go`, `flag_impl.go`, `flag_bool_with_inverse.go`, `flag_ext.go`, `flag_schema_type.go`, and `flag_schema_type_test.go`. The test file contains four runnable `TestSchemaType` functions covering built-ins, destination behavior, external branches including a custom non-Getter, and optional/legacy behavior. Both docs snapshots match generated output. The helper and test source add no comments; public interface documentation uses the repository's existing API style. Product-only review mirror: `../review/nero-product`, based on the same base SHA, with only these six Go files changed and new files marked intent-to-add. Generated doc correctness is documented separately above.

Byte counts from `nero-sizes.json`: six changed Go product files total 34,272 bytes at freeze, net growth 8,411 bytes over base; two generated doc snapshots total 116,488 bytes, net growth 1,206 bytes; one newly authored Nero spec artifact totals 11,552 bytes. Installed linked skill files, `.spec` installation config, `.git`, caches, and `.pilot` logs are excluded from authored artifact size. Sizes are descriptive, not scores.

The pass establishes the preregistered behavior and documentation checks for this snapshot. Independent product review has not yet been run; this report makes no winner claim. Confidence: 0.98.
