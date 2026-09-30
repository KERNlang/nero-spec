# Exploratory TextVar time probe

This probe was requested after the preregistered oracle and both first-pass reports were frozen. It is not part of the main-task score, does not alter the hidden oracle, and was not sent to either builder. The three runs used only private copies of frozen candidates, sequentially with `GOMAXPROCS=2`.

`review_textvar_time_test.go` SHA-256 `6363feceafb9a0b0df14fe4116aec6a582f10390e782fd2718ca5f1b6f5b239f` creates a standard-library `FlagSet.TextVar` for `time.Time`. In Go 1.26.3, `flag.textValue.Get()` returns its pointer; the probe records the runtime type and both schema answers, then asserts `date-time` as a proposed pointer-aware mapping.

| Frozen private snapshot | Getter runtime type | SchemaType | SchemaItemsType | Proposed pointer-aware assertion |
| --- | --- | --- | --- | --- |
| Nero first pass | `*time.Time` | `""` | `""` | RED, exit 1 |
| Spec Kit first pass | `*time.Time` | `""` | `""` | RED, exit 1 |
| Spec Kit repaired | `*time.Time` | `""` | `""` | RED, exit 1 |

Command for each snapshot: `GOMAXPROCS=2 go test -run '^TestReviewTextVarTime$' -count=1 -v .`. Exact logs and exit receipts: `nero-textvar-time.*`, `speckit-textvar-time.*`, and `speckit-repair-textvar-time.*` in this directory. Each log says `getter runtime type=*time.Time; SchemaType=""; SchemaItemsType=""` and fails only the proposed `date-time` assertion.

The original task asks for `SchemaType()` to return `"duration"`/`"date-time"` for `time.Duration`/`time.Time` values, or `""` when the flag does not map cleanly; it asks `extFlag` to inspect `e.Get()`. It does not explicitly state whether a pointer returned by a standard-library `Getter` must be dereferenced. This is a verified mapping limitation if pointer-aware introspection is desired, with unresolved normative scope. It is not reported as a main-task failure or a discriminator between arms. Confidence: 0.99 for the observed behavior; 0.70 that the request requires pointer dereferencing.
