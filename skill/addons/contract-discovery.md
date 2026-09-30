# Addon: contract-discovery

Verify both sides of a boundary before writing about it. Hook: core step 3.

## When to use

- The change crosses a boundary: frontend↔backend, service↔service, repo↔repo, team↔team, generator↔output, library↔consumers.
- Any shared contract trigger (API shape, exported type/enum, schema, generator output).
- Loaded on demand when a boundary is crossed and the preset does not enable it.

## What it adds to the spec

- `## Contract (Verified)` table (<50 lines), every row tagged.
- `## Clients` table — every consumer, live or dead, with evidence.
- `## Deploy Order` — who ships first and the skew window.
- For cross-repo work: `## Repos` table.

## Steps

- **Read the other side's source** (routes, controllers, DTOs, schemas, mappers, generators). Top-level session → subagent for context efficiency; already a dispatched worker → inline.
- **Check existing consumer patterns** before proposing new ones.
- **Enumerate every client** of the contract; mark each live/dead with evidence. Dead clients inflate blast radius; divergent live clients are common.
- **Trace the hop chain** per claim: shared type → serializer → transport/auth → route → validator → consumer. Cite producer AND consumer.
- Verify names, shapes, validation, casing and locale behavior from source — never memory.
- **Deploy order + skew window**: which side ships first, what happens while versions are mixed. A contract spec without this can pass self-audit while shipping a breaking order.
- Source inaccessible → tag that side ASSUMED, name the owner in Open Questions.

## Cross-repo

- List every repo on each side with its default branch and the commit read (`git rev-parse --short HEAD`).
- Claims cite `repo@sha:path:line`.
- **Version pinning**: how the consumer picks up the producer (published package, git ref, monorepo path, runtime API); cite where it is pinned.
- Can both repos release independently? If not, say which must wait.
- Spec lives in the repo whose code changes most; every other repo gets a one-line pointer file at `specs.path`.

## Cross-team

- Deploy order is **agreed with the owning team**, never assumed; record who agreed and when.
- Every ASSUMED claim on the other team's side is listed for that team by name.
- Cross-team integration → at least tier 3 / Full; contract table goes ahead of hypotheses.

## Patterns

```markdown
## Repos
| Repo | Default branch | Read at | Role |
|---|---|---|---|
| api-server | main | `a1b2c3d` | producer |
| web-client | main | `9f8e7d6` | consumer |

## Contract (Verified)
> Verified against: api-server@a1b2c3d, web-client@9f8e7d6 on 2026-01-31
| Field / Behavior | Type | Evidence | Tag |
|---|---|---|---|
| `status` | enum `active\|paused` | `api-server@a1b2c3d:src/dto/job.ts:14` | VERIFIED |
| `status` read as string | string | `web-client@9f8e7d6:src/api/jobs.ts:40` | VERIFIED |
| legacy CLI consumer | — | `grep -rn "/v1/jobs" cli/` → 0 hits, 2026-01-31 | VERIFIED (dead) |

## Clients
| Client | Live? | Evidence |
|---|---|---|
| web-client | live | deployed, calls `/v1/jobs` (`src/api/jobs.ts:40`) |
| admin-cli | dead | last commit 2024, no route references |

## Deploy Order
1. api-server adds `paused` (additive, old clients ignore it).
2. web-client renders `paused`.
Skew window: client on old version shows `paused` jobs as unknown → falls back to `active` label. Acceptable.
```

## Anti-patterns

- Field names or shapes written from memory or docs and tagged VERIFIED.
- Citing only the producer side.
- Blast radius counting dead clients as live, or missing a live one.
- "Both deploy together" without saying what happens if they don't.
- Copying the spec into every repo instead of pointer files.
