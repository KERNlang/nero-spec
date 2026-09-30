# First-pass evaluation runbook

This is an execution checklist for the parent-authorized frozen candidates. It adds no acceptance criteria to `../EVALUATION.md`. Do not read or run against an arm while its builder is working. Keep the evaluator and reference logs out of builder contexts.

## Before evaluation

1. Obtain the parent's explicit freeze authorization for each arm and exclusive test lease. Do not freeze an arm merely because it appears idle.
2. Confirm each arm remains based on `84d0da5c2dea82f19c9bce4bdf255ee1091231fa`; record `git rev-parse HEAD`, `git status --porcelain=v1 -uall`, `git diff --binary HEAD`, and the builder's declared focused test command. Save SHA-256 of the diff and of the two doc snapshots. Preserve the first-pass record before any feedback.
3. Archive the entire frozen arm, including untracked files, `.git`, installed framework links, product source, docs, and authored artifacts: `tar -C "$arm_path" -cf "$eval_root/frozen/$arm-first.tar" .`. Hash the archive with `shasum -a 256`. Extract it only into a private evaluator run directory. Never put the hidden test in the arm.
4. In each private run directory, require `eval_schema_test.go` to be absent, then copy the frozen oracle there. Verify SHA-256 `73ce5be25077b36113a25db5bf25a5bec9adc477f484f52dca4c5f3dd48da845`. Do not alter that file or the expected answers.

## Same checks for each arm, sequentially

- Builder's own narrow test command, exactly as declared; save output and exit status. Require `flag_schema_type_test.go` to exist and inspect its runnable tests for requested built-in and external branches.
- Hidden oracle: `go test ./ -run '^TestEval' -count=1 -v`.
- Common existing regression selection: `go test ./ -run '^(TestBoolWithInverseBasic|TestGenericFlagApply_SetsAllNames|TestIntFlagExt|TestUintFlagExt|TestStringSliceFlagApply_SetsAllNames|TestDocGetValue)$' -count=1 -v`. These six names exist in the pinned base and cover the inverse flag, custom generic value, standard-library flag wrappers, a slice flag, and the existing documentation value path. This is a targeted root-package run, not a full suite.
- Documentation: `go doc -all "$PWD"` into a private output file, then `cmp -s` that file separately with `godoc-current.txt` and `testdata/godoc-v3.x.txt`. Save both exit statuses. This matches the repository's `make generate` and `make v3approve` behavior without modifying the snapshot.
- Record Go version, exact commands, logs, exit statuses, compiler failures, and the nil `GenericFlag` subtest outcome. Run only one project test command at a time.

## First-pass report

Report the frozen source archive hash, tracked diff hash, status including untracked paths, doc hashes, test outcomes, and requested deliverable presence for each arm. Measure product change and authored framework artifact sizes separately: list changed product source/test/doc files with byte counts, and list newly authored specs/plans/tasks/checklists with byte counts. Exclude preinstalled Nero skill files, Spec Kit templates/infrastructure, `.git`, dependency caches, and `.pilot` logs from authored artifact totals. Treat size as descriptive, not a correctness score. If a repair round is offered, keep this first-pass report immutable and label the second pass as repair after feedback.
