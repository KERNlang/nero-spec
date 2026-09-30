# Supplementary Spec Kit review probe

This probe was added after the immutable first-pass report and is not part of the preregistered score. It ran only in `evaluator/runs/speckit-first`; the frozen arm and frozen archive were not modified. The original hidden oracle remains SHA-256 `73ce5be25077b36113a25db5bf25a5bec9adc477f484f52dca4c5f3dd48da845`.

The repository's `command_setup.go:78-85` appends every non-test standard-library flag as `extFlag` when `AllowExtFlags` is enabled. The standard-library `FlagSet.Func` creates `flag.funcValue`, which implements `flag.Value` but has no `flag.Getter`. The candidate's `flag_ext.go:28` asserts `e.f.Value.(flag.Getter)` without checking. Both new schema methods call `e.Get()`.

`review_ext_nogetter_test.go` SHA-256 `2cf5ba545e61540c3c8088b85cc6ed7b25c3f20d0f8ec9ff05b47d2ef4c63b26` wraps a real `FlagSet.Func` entry and separately invokes both schema methods. `GOMAXPROCS=2 go test -run '^TestReviewExternalNonGetter$' -count=1 -v .` ended at 2026-09-29T17:29:47Z with exit 1. Both subtests failed with `interface conversion: flag.funcValue is not flag.Getter: missing method Get`. Exact output: `speckit-review-ext-nogetter-red.log`; exit receipt: `speckit-review-ext-nogetter-red.exit`.

The test demonstrates a real integration failure and sets a RED repro before any repair. It does not change the earlier passing test, build, vet, or documentation results. Confidence: 0.99.
