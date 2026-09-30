# Addon: release-contract

Client↔backend changes where clients update on their own schedule (mobile apps, desktop apps, installed CLIs, SDKs). Hook: core step 3, after `contract-discovery`.

## When to use

- A backend change is consumed by a client the user must update (store apps, installed software).
- A client change depends on a backend capability that may not be deployed yet.
- Loaded on demand for any client↔backend release, even when the preset does not enable it.

## What it adds to the spec

- `## Release Contract` section with four parts: versions in the wild, compatibility window, deploy order, rollback.
- Acceptance criteria covering at least one old client version against the new backend.
- Release-time live check: `e2e-sweep` (when enabled) runs the old-client row and the new client against the release backend before go-live.

## Required sections

### Versions in the wild

- Which client versions are still in use, and the evidence (analytics, store console, minimum-version setting, telemetry query + date).
- No evidence → ASSUMED, and the oldest version you must support is an OPEN or a stated default.

### Compatibility window

- How long the backend must serve old clients unchanged; what forces an upgrade (minimum-version gate, forced update screen, API version header).
- Additive vs breaking per field/endpoint: additive = new optional fields/endpoints; breaking = removed/renamed fields, changed types, tightened validation, changed semantics.

### Deploy order

- Default: backend first (additive), clients next, removal of old behavior last — after the window closes.
- Client-first only when the client feature-detects the backend and degrades cleanly; state how.
- App-store review delay and staged rollout are part of the skew window.

### Rollback

- Backend rollback with new clients already installed: what breaks?
- Client rollback is usually impossible once shipped — say so, and what the kill switch is (remote config, feature flag, server-side toggle).

## Pattern

```markdown
## Release Contract
| Client version | Share | Evidence | Works with new backend? |
|---|---|---|---|
| 2.4.x | 61% | store console, 2026-01-31 | yes — new field ignored |
| 2.3.x | 30% | store console, 2026-01-31 | yes |
| ≤2.2 | 9% | store console, 2026-01-31 | NO — strict decoder rejects unknown enum |

Window: backend keeps `/v1/sync` shape until ≤2.2 share < 1% or min-version gate raised to 2.3.
Order: backend (additive) → app 2.5 → raise min-version → remove legacy path.
Rollback: backend revert safe (2.5 treats missing field as default). Kill switch: `sync_v2` remote flag.
```

## Anti-patterns

- Assuming everyone runs the latest client.
- Removing a field in the same release that stops using it.
- Tightening validation on the backend without checking what old clients send.
- A deploy order without the app-store review and staged-rollout delay.
- No kill switch for a client change that cannot be rolled back.
