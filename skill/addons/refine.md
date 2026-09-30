# Addon: refine

Make the drafted spec survive contact with the code before anyone builds from it. Hook: core step 8 (after the draft is saved, before approval and build); again on resume (core step 1) and before go-live / release. On by default in every preset.

## When to use

- Every spec, every preset. Depth decides how much:
  - **Surgical / tier 1** — steps a + d (max 3 questions) + e with one critic, one round. Nothing else.
  - **Full / tier 2+** — all steps a–g.
- **Resume** (new session on an existing spec, or the spec is older than its last covered-path change) → a + c first, then continue.
- **Before go-live / release** → a + b + c again; a spec is not DONE while a consumer is unmerged or stale. `e2e-sweep` enabled → its live run follows, with open findings as scenarios.

## Steps

### a. Mechanical check

```sh
<skill dir>/scripts/spec-check.sh --spec <spec file> [--repos <name=path,...>]
```

`--repos` comes from `.spec` `repos:`; name every repo the `## Changes` block and Contract rows touch. Fix each finding in the spec itself (Status, dead cites, unchecked ACs, repeated fixes → escalate). A `REPEAT-FIX` finding means this spec is too small for the area: widen it, or write a bigger one, before adding a fifth fix. A `NO-REVIEW` finding (Status past SPEC, no `## Refine` block naming its Critic) is cleared only by steps e and g, never by editing the Status line alone.

### b. Contract compare (cross-repo / client↔server only)

Step a already did the mechanical part for every endpoint row in `## Contract` (`| Endpoint | Fields | Producer | Consumers |`):
- `CONTRACT-MISSING` — endpoint absent from a repo's default branch or HEAD, with the branches that do have it;
- `CONTRACT-FIELDS` — a producer field no consumer call site of that endpoint names (±15 lines, snake/camel/Pascal/kebab; rows with Producer and Consumers only);
- `UNMERGED` — Status READY/DONE but ADDED paths are not on the default branch.

Your part:
- confirm or dismiss each finding by opening both sides (the heuristic misses types declared away from the call, generated clients, prefix-built routes) and cite `file:line` on **both** sides;
- compare what the script cannot parse: enums, error codes, types, nullability, contracts not in endpoint-row form (or rewrite them into rows so the next run checks them);
- the shipping branch is the one the release ships from; a consumer change only on a side branch or worktree is unmerged.

Each confirmed mismatch → finding, severity HIGH when it touches auth/session/money/data loss. Consumer side unmerged → HIGH, and Status cannot pass READY for release.

### c. Re-verify claims

- Re-run every VERIFIED claim's citation/command against the current code, including other repos (`repo@sha:path`). Changed → fix the claim and add a Corrections Log row.
- Re-check every ASSUMED claim. Now checkable → VERIFIED with citation, or wrong → corrected.
- **ASSUMED older than the anchor** (`Verified at` / `Date`) or carried over from an earlier session: re-check it now or turn it into OPEN. Never build on an assumption nobody re-read (e.g. "backend is greenfield").
- Bump `Verified at` once done.

### d. Blind-spot pass (every depth)

First check that the spec has, each missing item a finding (HIGH when an escalation trigger fired):
1. **Tricky inputs** — every AC has a `Tricky inputs:` line naming ≥ 2 concrete values or states (Surgical ≥ 1). "Edge cases", "invalid input" are categories, not inputs.
2. **Callers** — every changed function, type or field has a `Callers:` line from a cited grep, covering call sites and construction paths (literals, pools, tests), each marked `changes` / `same`.
3. **Real usage** — every decision has a `Real usage:` line with evidence. Stricter accessor, narrowed input or forbidden sequence chosen without it → reopen the decision.
4. **Waived hazards** — grep the spec for "safe", "no handling needed", "bounded", "idempotent", "not possible", "out of scope". Each without a VERIFIED citation → a Tricky input with a test.
5. **Downstream / History** — `Downstream:` present when output feeds another layer; `History:` command run.
6. **Mutation probe** — propose 3–5 realistic bugs an implementer could write from this spec (wrong accessor, missing await, unguarded shared state, degenerate input, reused buffer). Each must fail at least one AC's named test; a survivor becomes a Tricky input. Effective agon on → `agon nero` with this as its brief; off → the step e critic does it.

Then ask the questions that apply — Surgical: questions 1–3 only, max 3; Full: max 6. Each answer becomes an AC or Tricky input (or an Out-of-Scope line), never a new section.

| # | Area | Question |
|---|---|---|
| 1 | Caller order | Who calls this, in what order, from outside the repo (middleware, hooks, third-party libraries, retries)? What partial state can they leave? |
| 2 | Real input | What does the ecosystem actually send: renamed fields, empty/zero/root values, repeated or chained calls? |
| 3 | Construction | Can the object exist without the constructor (literal, factory, zero value, test fixture)? |
| 4 | States | Empty, loading, error, offline, concurrent calls — under which runtime concurrency model? |
| 5 | Security / privacy / abuse | Who can call it, rate limit, enumeration, data leaked in errors or logs, untrusted input reaching an AI prompt? |
| 6 | Old clients / migration | What do installed old clients or existing rows do on the new shape? |
| 7 | Text / a11y | Longest translation fits, grammar per locale, screen reader label, focus order, contrast? |

### e. Critique by risk

Input: the spec + open findings only, never the chat history.

| Condition | Critic |
|---|---|
| Effective agon on, normal risk | `agon nero "<spec path>"` |
| Effective agon on, high risk (auth, guest, payment, persistence, deletion, privacy, destructive fs/process ops, shared contracts) | `agon tribunal` or `agon council` |
| `agon: restricted` | same mode, only `agon_engines`, passed explicitly; report the shortfall if the risk needs more |
| Effective agon off, or restricted without engines | fresh-context subagent (or a new session, never the writing one) with steps b–d as its checklist; say it is same-model |

Rules of record decide the exact flags. Each critique finding is verified against the code before it changes the spec. Rejecting a finding needs evidence that disproves it: a code citation that covers every construction path, or command output; a requirement, UX or external-system finding needs the owner's decision instead. Without that evidence a code finding becomes a Tricky input with a named test — test it, don't argue it.

### f. Decision push

- Max **2** refine rounds (a round = steps a–e once). No third round.
- After round 2 every remaining OPEN is either decided — recommended option, recorded `ASSUMED: <choice>, because <why> (owner: <name>)` — or escalated to the user in **one line** each.
- `Contested:` lines (`contested-decision-scan`) keep their picked reading when forced to ASSUMED; see that addon.
- Options that nobody will pick are deleted, not kept "for completeness".

### g. Record

Add or replace one `## Refine` block, ≤ 6 lines:

```markdown
## Refine
Round 2/2, 2026-01-31, `Verified at` a1b2c3d. Critic: agon nero (normal risk).
Fixed: 4 (contract: `refresh_token` dropped by client type; Callers: 2 missed sites; Tricky input added: expired token on refresh retry).
Decided: OPEN-2 → ASSUMED keep v1 endpoint (owner: backend lead).
Rejected: 1 (critic: "`limit` may be negative" — `api/parse.go:12` rejects < 0 before any caller reaches it).
Residual risk: old clients ≤2.2 untested on device.
Pass: yes (0 HIGH open).
```

**Pass** = no unresolved HIGH finding. Fail → Status stays SPEC; say which finding blocks.

## Anti-patterns

- Refine as a rewrite: the spec gets longer. Findings shrink or sharpen the spec; blind-spot answers go into ACs and Tricky inputs.
- Settling an ambiguity with the strictest existing accessor because it looks canonical.
- Comparing the contract against the consumer's feature branch while the release ships from another branch.
