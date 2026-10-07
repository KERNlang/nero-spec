# Addon: changed-things

Hook: core step 4.

Replaces core one `Callers:` line per symbol and `Real usage:` (step 4) while loaded.

## When to use

Changes to shared things other code or repos depend on. Internal-only changes stay a short list.

## What it adds to the spec

```markdown
| Changed thing | Kind | Scope | Contract change | Used by (count, where) | Tests covering it | Why | Risk / reachable via | Evidence |
```

- Kind: function, prop, event, CSS class, token, route, store field, test id.
- Contract change: none · additive · breaking.
- *Used by* also searches sibling repos (E2E suites using selectors, CMS templates sharing CSS).
- Evidence = the cited search + count.
- **Precedent:** reuse candidates go in `## What Already Works`; each option adds `Precedent: <where this pattern already exists> (<file>, <size>)` so its size can be compared.

## Anti-patterns

- A count without the search that produced it.
- Searching only the current repo for a shared selector or class.
- An option with no precedent line, so reuse and new code cannot be compared by size.
