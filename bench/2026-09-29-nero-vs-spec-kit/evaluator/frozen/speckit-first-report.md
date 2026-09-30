# Spec Kit first pass: cli-01

Candidate freeze authorized by parent at 2026-09-29T17:21:20Z. Evaluator observed the arm at 17:22:03Z and archived it at 17:22:20Z. Builder edits had stopped. This report records the first pass before any feedback or repair. No source was changed in the arm; all checks used `evaluator/runs/speckit-first` extracted from the frozen archive. Test lease was released after the checks.

## Snapshot identity

- Base and arm HEAD: `84d0da5c2dea82f19c9bce4bdf255ee1091231fa`.
- Full arm archive, including untracked source, docs, Spec Kit artifacts, and `.git`: `speckit-first.tar`, SHA-256 `79bb17fce05f3fa65081e927f50d4239530c523113204ab7069cdf219e15d75e`.
- Tracked patch: `speckit-tracked.diff`, SHA-256 `fc7b61c9a7ea7b5a95ee2afe91fd83c09df9727e3ada0ca3d5e5c804795fb9c4`. Untracked files are captured in the archive and `speckit-status.txt` (SHA-256 `9c8ec4f51ef4354b49c8832f07c1726a587c2521ae697090e3f37a454872dde2`).
- `godoc-current.txt` and `testdata/godoc-v3.x.txt` both SHA-256 `be1af875575ae0ba21b197f2ea533ee1b4f4c44485c3d4a1f1b869556c644c9d`; hash receipt in `speckit-doc-hashes.txt`.
- Hidden oracle copied into private run snapshot only, SHA-256 `73ce5be25077b36113a25db5bf25a5bec9adc477f484f52dca4c5f3dd48da845`.
- Go version: `go1.26.3 darwin/arm64`. `GOMAXPROCS=2` was used for all Go commands.

## Gates

| Check | Exact command or comparison | Exit | Evidence |
| --- | --- | ---: | --- |
| Builder's focused tests | `GOMAXPROCS=2 go test -run '^(TestFlagSchemaType|TestBoolWithInverseBasic|TestGenericFlagValueFromCommand|TestStringSliceFlagValueFromCommand)' -count=1 .` | 0 | `../runs/speckit-own-test.log`, `.exit` |
| Frozen hidden oracle | `GOMAXPROCS=2 go test ./ -run '^TestEval' -count=1 -v` | 0 | `../runs/speckit-oracle.log`, `.exit` |
| Common six regressions | `GOMAXPROCS=2 go test ./ -run '^(TestBoolWithInverseBasic|TestGenericFlagApply_SetsAllNames|TestIntFlagExt|TestUintFlagExt|TestStringSliceFlagApply_SetsAllNames|TestDocGetValue)$' -count=1 -v` | 0 | `../runs/speckit-common-regressions.log`, `.exit` |
| Compile | `GOMAXPROCS=2 go build ./...` | 0 | `../runs/speckit-build.log`, `.exit` |
| Vet | `GOMAXPROCS=2 go vet .` | 0 | `../runs/speckit-vet.log`, `.exit` |
| Docs generation | `GOMAXPROCS=2 go doc -all "$PWD"` to private output | 0 | `../runs/speckit-godoc-generated.txt`, `.exit` |
| Current docs match | `cmp -s` generated output against `godoc-current.txt` | 0 | `../runs/speckit-godoc-current-compare.exit` |
| Promoted docs match | `cmp -s` generated output against `testdata/godoc-v3.x.txt` | 0 | `../runs/speckit-godoc-promoted-compare.exit` |

The hidden nil `GenericFlag.SchemaItemsType` case passed. The common regression run had two existing `TestIntFlagExt` base-16 subtests skipped by that test's own condition; the command exited 0. No full suite ran.

## Deliverables and size

The six requested product Go files are present or changed: `flag.go`, `flag_impl.go`, `flag_bool_with_inverse.go`, `flag_ext.go`, `flag_schema_type.go`, and `flag_schema_type_test.go`. The test file contains four runnable `TestFlagSchemaType` functions covering built-ins, unknown/generic values, inverse bool, and standard/external flag branches. Both docs snapshots match generated output. The helper and test source add no comments; public interface documentation uses the repository's existing API style. Product-only review mirror: `../review/speckit-product`, based on the same base SHA, with only these six Go files changed and new files marked intent-to-add. Generated doc correctness is documented separately above.

Byte counts from `speckit-sizes.json`: six changed Go product files total 32,612 bytes at freeze, net growth 6,751 bytes over base; two generated doc snapshots total 116,240 bytes, net growth 958 bytes; eight newly authored Spec Kit spec/plan/task/checklist artifacts total 12,907 bytes. Installed `.agents` skills, `.specify` infrastructure/templates, `.git`, caches, and `.pilot` logs are excluded from authored artifact size. Sizes are descriptive, not scores.

The pass establishes the preregistered behavior and documentation checks for this snapshot. Independent product review has not yet been run; this report makes no winner claim. Confidence: 0.98.
