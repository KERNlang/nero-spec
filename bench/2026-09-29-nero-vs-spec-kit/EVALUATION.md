# Paired development pilot: cli-01

This protocol is for the parent orchestrator. Keep this file, the evaluator directory, prior specifications and grades, the later fix, and the reference PR history out of builder prompts and directories. Dispatch both arms with the exact text in `evaluator/BUILDER_TASK.md`, starting from independent copies of base commit `84d0da5c2dea82f19c9bce4bdf255ee1091231fa`. Only the framework differs: Nero versus the cloned Spec Kit. The parent owns dispatch, timing, freezes, all AI calls, and scoring.

## Frozen evaluator

- File: `evaluator/eval_schema_test.go`; SHA-256 `73ce5be25077b36113a25db5bf25a5bec9adc477f484f52dca4c5f3dd48da845`.
- Test names begin `TestEval`, so builder-authored tests can coexist.
- The test uses `Flag` and the optional public interfaces for all built-in flag types, checks a declared `BoolWithInverseFlag`, exercises standard-library `flag.FlagSet` wrappers plus time and channel-valued custom getters, and calls `SchemaItemsType` on a nil-valued `GenericFlag`.
- It checks observable type answers and interface availability. It does not inspect the implementation or compare source text.

## Reference discrimination

The evaluator clone was made from the benchmark's base worktree and is isolated at `evaluator/base`. Only that clone fetched the reference commits from the upstream repository. The original source worktree and builder trees were not changed or fetched into.

| Revision | Narrow oracle result | Evidence |
| --- | --- | --- |
| Base `84d0da5c2dea82f19c9bce4bdf255ee1091231fa` | RED: compilation fails because `SchemaTyper` and `SchemaItemsTyper` do not exist | `evaluator/base-red-v2.log` |
| Original feature `024fc6f75352d12483eda69e40ee565b822e281c` | RED: built-in cases pass, nil `GenericFlag.SchemaItemsType` panics at `flag_impl.go:320` | `evaluator/feature-red-v2.log` |
| Follow-up fix `8294cc82f6f4340340ec5b9373488cb1c799c80b` | GREEN: all evaluator cases pass | `evaluator/fix-green-v2.log` |

The command for each reference run was `go test ./ -run '^TestEval' -count=1 -v` with Go 1.26.3. This is a focused root-package test, and Go compiles the package and test file. No full local suite ran.

## Pre-registered scoring

1. Freeze both builder workspaces before evaluation. Record each arm's base SHA, final commit and dirty diff, elapsed wall time, framework version or copied source SHA, prompt, and tool calls. Use the same time and intervention policy for both arms.
2. Copy each frozen arm into a separate private evaluator snapshot. Add `eval_schema_test.go` to the snapshot root only after the builders have stopped. If a file with that name already exists, stop and inspect the collision; never overwrite it. Confirm its SHA-256 matches the frozen evaluator.
3. Run `go test ./ -run '^TestEval' -count=1 -v` in each snapshot, one run at a time, saving full output and exit code. A compile failure, panic, or assertion failure is a correctness failure. Record the nil `GenericFlag` result separately because it is the discriminating hidden case. Run the builder's own focused schema tests using their declared narrow command, and record that result separately.
4. In each snapshot, require `flag_schema_type_test.go` to exist and contain runnable schema tests. Run `go doc -all "$PWD"` to a private evaluator output file, then byte-compare that output with both `godoc-current.txt` and `testdata/godoc-v3.x.txt` using `cmp -s`. Each comparison must pass. This is the repository's actual generation behavior from `scripts/build.go` (`make generate`), followed by its promotion step (`make v3approve`). It passed on the reference fix with Go 1.26.3. Also inspect the final diff for requested public interfaces, generic built-in coverage, `BoolWithInverseFlag`, and `extFlag`; record any missing deliverables separately from the hidden oracle.
5. Report both arms with the same categories: feature behavior, nil-interface safety, docs and tests, compile result, time and token/tool cost, and review findings. Do not select a winner from one passing test alone; use the complete requested feature and evidence. Do not relax the oracle after seeing either arm.

The oracle does not assess code quality, comment policy, documentation rendering, custom `GenericFlag` values with their own schema methods, or the unrelated pre-existing `PostParse` nil dereference also changed by the later fix. Those require separate review if relevant. The user's task is ordinary implementation work; do not frame either builder task as a future product or specification-authoring workflow.

## Adversarial challenge disposition

- Nil `GenericFlag` remains in scope. The requested generic implementation makes `SchemaItemsTyper` available on every built-in flag, including `GenericFlag`; an absent custom value must return `""` without a panic. Dynamic delegation to a custom value is permitted, but it must also handle nil. The evaluator intentionally does not dictate the nonnil custom-value policy.
- The inverse-bool delegation claim does not match this repo: `BoolWithInverseFlag` has no embedded `BoolFlag`. Its schema methods can answer before parsing, as the original feature's own tests do. The fixture now has a normal name.
- The external unknown case uses a channel rather than a struct, removing the possible `object` mapping ambiguity.
- If both arms receive an equal failure-feedback correction round, freeze and report first-pass results before sharing feedback. Call the second pass a repair measurement; do not claim its oracle remained unseen.
- Documentation is graded with the exact generated output comparison above, not a file timestamp or a subjective percentage.
