# Implementation Plan: Typed Flag Schema Introspection

**Branch**: `base 84d0da5 (isolated detached checkout)` | **Date**: 2026-09-29 | **Spec**: [spec.md](spec.md)

## Summary

Expose two optional flag metadata interfaces. Map accepted Go value types through one shared helper, with `FlagBase` and `extFlag` delegating to it and `BoolWithInverseFlag` returning its known boolean type. Add focused branch coverage, then regenerate public godoc snapshots.

## Technical Context

**Language/Version**: Go 1.22 module

**Primary Dependencies**: Go standard library; existing testify in tests

**Storage**: N/A

**Testing**: Targeted `go test` name filter and Go compile/type check, with a test lease

**Target Platform**: Go library on supported Go platforms

**Project Type**: Library

**Performance Goals**: Introspection is constant-time for scalar types and one reflection step for slices/maps

**Constraints**: No parsing required; optional interfaces preserve custom Flag implementations; no full local suite

**Scale/Scope**: Four existing production source files, one mapping helper, one focused test file, two godoc snapshots

## Constitution Check

- I Stable Optional Interfaces: pass; do not expand `Flag`.
- II Accepted Value Semantics: pass; use typed `Get()` without lifecycle calls.
- III Focused Verification: planned focused tests and godoc regeneration.
- IV Backward Compatibility: pass; no parse/help changes.
- V Simplicity: pass; one mapping helper with unknown fallback.

Rechecked after design: no exceptions or violations.

## Project Structure

### Documentation (this feature)

```text
specs/001-typed-flag-schema/
├── spec.md
├── checklists/requirements.md
├── plan.md
├── research.md
├── data-model.md
├── contracts/flag-schema.md
├── quickstart.md
└── tasks.md
```

### Source Code (repository root)

```text
flag.go
flag_impl.go
flag_schema_type.go
flag_bool_with_inverse.go
flag_ext.go
flag_schema_type_test.go
godoc-current.txt
testdata/godoc-v3.x.txt
```

**Structure Decision**: Keep the optional public interfaces beside other flag interfaces and the shared type mapping in a small dedicated Go file.
