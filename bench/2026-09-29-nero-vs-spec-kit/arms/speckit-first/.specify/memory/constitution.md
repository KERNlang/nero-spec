<!--
Sync Impact Report
Version change: unfilled scaffold -> 1.0.0
Modified principles: none; initial adoption
Added sections: Additional Constraints, Development Workflow
Removed sections: none
Follow-up TODOs: none
Remove this report before committing the constitution.
-->
# urfave/cli Constitution

## Core Principles

### I. Stable Optional Interfaces
New metadata capabilities MUST use optional interfaces unless a breaking public contract is explicitly required. Existing Flag implementations MUST remain valid, because downstream callers may define their own flags.

### II. Accepted Value Semantics
Metadata MUST describe values accepted by a flag, independently of defaults or parsing state. Equivalent built-in and wrapped standard-library values MUST yield the same type metadata.

### III. Focused Verification
Behavior changes MUST have focused tests for the requested type branches and edge cases. Project checks MUST remain targeted to changed behavior; generated reference artifacts MUST be updated when public documentation changes.

### IV. Backward Compatibility
Existing parsing, help rendering, and flag lifecycle behavior MUST remain unchanged unless a feature explicitly requests them. New metadata MUST NOT require callers to execute lifecycle methods.

### V. Simplicity
Implementations MUST use the smallest coherent mapping of Go value types to metadata. Unknown or ambiguous types MUST return an empty string rather than guess.

## Additional Constraints

This repository is a Go CLI library targeting the version declared in `go.mod`. Hand-written source files MUST remain under 500 lines where practical. Code comments MUST satisfy the canonical engineering Comment Policy.

## Development Workflow

Use a written feature specification, plan, and task list before implementation. Run the focused local gate, inspect the resulting diff, and route independent post-implementation review through the parent orchestrator. Do not claim completion from static inspection alone.

## Governance

Amendments require a documented rationale, version bump, and review of dependent feature artifacts. Use semantic versioning for this constitution: major for incompatible principle changes, minor for new principles, and patch for clarifications. Every implementation review MUST check applicable principles.

**Version**: 1.0.0 | **Ratified**: 2026-09-29 | **Last Amended**: 2026-09-29
