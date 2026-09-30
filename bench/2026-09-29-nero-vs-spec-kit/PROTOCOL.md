# Preregistered developer pilot: Nero Spec and Spec Kit

**Registered:** 2026-09-29, before builder dispatch  
**Task:** `cli-01`, a normal developer feature in `urfave/cli`  
**Target base:** `84d0da5c2dea82f19c9bce4bdf255ee1091231fa`  
**Nero Spec pin:** `3cd52c378eea12394a25cd46d88698623b0e37f2`  
**Spec Kit pin:** `2c0a57abe1e7383a864c7d5e4dfa2457d7537734`  
**Design confidence:** 0.94; this protocol controls a small paired pilot, not a general framework ranking.

## Question and design

Can each framework guide the same model through this feature while producing a correct, reviewable change? Compare the arms on observed functional behavior, regressions, independent review findings, artifacts, and elapsed work. The task was selected because dependencies are cached and the change is small. Both arms historically scored `3/3` on the bug-detection rubric for this case; it is neither a known Nero win nor a prospective result. One task and one seed cannot rank frameworks.

The setup owner creates two isolated arms from the exact base and pins the corresponding framework. `INPUTS.json` records the common original task verbatim, base and framework revisions, setup receipts, and arm paths. The oracle owner writes `EVALUATION.md` and held-out tests before builders see either arm. Neither owner edits the other's artifact. This protocol is fixed before implementation; record any later deviation with its reason and time rather than silently rewriting criteria.

## Assignment and information boundary

Dispatch one fresh-context `gpt-6-sol` builder at high reasoning to each arm, in parallel. Both receive the identical original task, target base, common code-quality and safe-scope rules, local-test lease procedure, and acceptance boundary. Each receives only its assigned framework's native instructions and files. The Nero builder follows Nero's required independent prebuild critic, routed by the parent; the Spec Kit builder follows Spec Kit's native process and may use its optional documents without being forced to create them. Do not import Nero skill instructions into the Spec Kit arm or flatten the two frameworks into a common artificial workflow.

Builders may read only their assigned arm, assigned framework, the shared original task and common policies. They may not inspect future truth, old specs, grades, evaluator files or tests, the other arm, or outcomes from the other builder. They may not fetch the target repository from the network or inspect target history beyond the pinned base and its ancestors. Product-source edits stay inside the assigned arm. The parent records framework-specific calls, including the Nero critic, as workload and latency rather than treating unequal process requirements as equal effort.

## Execution and timing

Record setup and framework bootstrap separately from developer-task elapsed time. Start each task clock when its builder receives the ready arm and original task; stop at its first frozen implementation. Record wall-clock timestamps and active tool/call intervals where available. Parallel waits, test-lease waits, and independent review time are separate fields. Waiting time alone supports no performance inference.

Builders may run targeted checks only when the parent grants the single test lease; the parent serializes all test execution across both arms. Record command, arm revision, start/end, exit status, and relevant output. No simultaneous test runs. The same common local gate applies to both arms, alongside any framework-native checks required by the assigned process. The parent records failures as observed rather than concealing them through retries.

At first completion, freeze each arm's implementation as an immutable commit, patch, or equivalent content snapshot **before** the builder receives held-out feedback. Record its hash and first-pass local-gate result. The evaluator then applies the prewritten oracle to each frozen first-pass snapshot under the test lease. Preserve those scores and raw failures. If a failure needs correction, allow at most one equal failure-feedback correction round per arm, with the same level of diagnostic detail and a fresh frozen correction snapshot. Keep first-pass and corrected outcomes separate; do not replace the former with the latter.

After local gates, the parent routes independent Agon post-implementation review for both arms under the applicable repository policy and records reviewer identities and findings. Verify findings against each arm's actual code. Review findings remain visible even if the correction round resolves them. Review is not a substitute for oracle execution.

## Outcomes and reporting

For each first-pass and, if used, corrected snapshot, report:

1. Functional pass/fail against each prewritten oracle criterion, with raw command and result.
2. Targeted regression result and any observed behavioral regression.
3. Independent review findings, severity, verification, and disposition.
4. Changed product files and code diff size; framework-generated and builder-authored documentation bytes and lines, separately.
5. Bootstrap, task, test-lease wait, feedback, and review elapsed times; model and tool-call counts when observable.

Bytes and lines are output proxies, **not** actual context tokens. Actual context-token use is unavailable unless a runtime supplies a direct measurement, in which case label its source and scope. Do not award subjective points for a planning stage, document quantity, or rule quantity. Report the functional and review evidence first, then workload and artifacts. A clean result in one arm or a difference between arms is a case-specific observation, not a causal claim about context size or a general framework advantage.

## Interpretation limits

This is a historical known case with one seed and a shared model. Cached dependencies and parallel dispatch aid feasibility but do not make the workloads identical. Native process differences, including Nero's required prebuild critic, remain part of the observed cost. A held-out test can miss defects, and an independent review can find issues outside that oracle. Report uncertainty and deviations explicitly; do not infer framework performance from idle or lease-wait time.
