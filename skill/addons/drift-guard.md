# Addon: drift-guard

Keep specs and code from silently diverging. Advisory only — never blocks CI. Hooks: core step 4 (header), core step 1 on resume, before editing code, core step 9.

## When to use

- On by default in every preset (it is automatic: the `## Changes` block is the anchor). Turn off per repo with `.spec` `addons: -drift-guard`.
- Matters most where specs outlive the change (shared code, long-lived features, multiple contributors).

## Config (`.spec`)

| Key | Values | Default |
|---|---|---|
| `drift` | `record` \| `living` | `record` |

- **record** — spec frozen at DONE. Later changes to covered files get a new spec with `**Supersedes:** <old path>`; the old spec gets `**Superseded by:** <new path>`.
- **living** — spec updated in place; bump `Verified at` on each update and log the change in Corrections Log.

## What it adds to the spec

```markdown
**Verified at:** a1b2c3d
**Drift:** STALE since 9f8e7d6    (only when detected)
**Supersedes:** / **Superseded by:**    (record mode)
```

- Non-git target: anchor `**Verified at:** dir-hash <sha256> root <dir>`, printed by `scripts/spec-check.sh --spec <file> --dir-hash <root>`; the check compares the hash (prunes `.git`, `node_modules`, `.DS_Store`; globs are not hashed).
- Covered paths = the `## Changes` block (core step 4). Older specs: `**Covers:**` header or the Blast Radius section still work.
- Generated code: cover the source that generates it (the generator's input, never the generated output).

## Steps

- **Open or resume a spec:** `git diff --stat <Verified at>..HEAD -- <Changes paths>`. Changes → set `**Drift:** STALE since <HEAD sha>`, re-run the commands behind load-bearing VERIFIED claims before relying on them; changed results → Corrections Log.
- **Before editing code:** find specs covering the files you will change:
  `scripts/spec-check.sh --touching <file list>` (or grep the specs folder for the path). For each hit: update it (living), supersede it (record), or write "not affected: <spec>" in the change summary.
- **Converge (step 9):** every AC-linked test still exists under its name (`grep -rn "AC-3" <test dirs>`). A deleted or renamed AC-linked test is a drift signal → fix the link or record it in As-built delta.
- **Script:** `scripts/spec-check.sh [repo-dir]` in this skill's folder (`--spec <file>` for one spec) lists STALE specs, dead/stale VERIFIED citations, dishonest or free-text Status, repeated fixes, broken pointers. Other-repo paths use `name:path`, resolved via `repos:` in `.spec` (or `--repos name=path`). DONE specs without a sha are checked against their last commit only while drift-guard is on (or `--stale`). Non-git target → `NO-GIT`: file-only checks still run, git checks are skipped. Exit 0 always; findings gate only under `--strict` (exit 1). Optional advisory pre-commit hook: `scripts/pre-commit-spec-check.sh` (`/spec init` offers it). `spec-drift.sh` is an alias.

## Anti-patterns

- Changes / `Covers:` pointing at generated output.
- Clearing STALE without re-verifying.
- Editing a DONE spec in record mode instead of superseding it.
- Wiring the script into CI as a blocking gate.
