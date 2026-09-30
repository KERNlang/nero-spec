# Supplementary Nero review probe

This probe was added after first-pass criteria were frozen and is not part of the preregistered score. It ran only in `evaluator/runs/nero-first`; the frozen arm and archive were not modified. The original hidden oracle remains SHA-256 `73ce5be25077b36113a25db5bf25a5bec9adc477f484f52dca4c5f3dd48da845`.

`review_ext_nogetter_test.go` SHA-256 `2cf5ba545e61540c3c8088b85cc6ed7b25c3f20d0f8ec9ff05b47d2ef4c63b26` wraps a real standard-library `FlagSet.Func` value, which has no `flag.Getter`, and separately invokes both schema methods. `GOMAXPROCS=2 go test -run '^TestReviewExternalNonGetter$' -count=1 -v .` ended at 2026-09-29T17:34:48Z with exit 0; both subtests passed. Exact output: `nero-review-ext-nogetter.log`; exit receipt: `nero-review-ext-nogetter.exit`.

This is a robustness observation separate from the preregistered first pass. It does not alter the earlier oracle, test, build, vet, or documentation results. Confidence: 0.99.
