# Tasks: Typed Flag Schema Introspection

**Input**: Design documents in `specs/001-typed-flag-schema/`

**Prerequisites**: `spec.md`, `plan.md`, `research.md`, `data-model.md`, `contracts/flag-schema.md`

**Tests**: Required by FR-006; write focused tests before production code.

## Phase 1: Setup

- [X] T001 Verify current flag family aliases and godoc generation path in `flag_*.go` and `scripts/build.go`.

## Phase 2: Foundational

- [X] T002 Add optional `SchemaTyper` and `SchemaItemsTyper` interfaces in `flag.go` per FR-001.
- [X] T003 Add focused tests for built-in schema mappings and unknown values in `flag_schema_type_test.go` per US1.

## Phase 3: User Story 1 - Describe built-in accepted types (Priority: P1) MVP

**Goal**: Introspect every ordinary built-in flag before parsing.

**Independent Test**: Target `TestFlagSchemaTypeBuiltins` and `TestFlagSchemaTypeUnknown`.

- [X] T004 [US1] Implement shared Go type mapping in `flag_schema_type.go` per FR-002 and FR-003.
- [X] T005 [US1] Add both methods to generic `FlagBase` in `flag_impl.go` per FR-004.

## Phase 4: User Story 2 - Describe special and external flags (Priority: P2)

**Goal**: Introspect inverse bool and wrapped standard-library flags.

**Independent Test**: Target `TestFlagSchemaTypeSpecial` and `TestFlagSchemaTypeExternal`.

- [X] T006 [US2] Add inverse bool and external getter branch tests in `flag_schema_type_test.go` per FR-006.
- [X] T007 [US2] Add both methods to `BoolWithInverseFlag` in `flag_bool_with_inverse.go` per FR-004.
- [X] T008 [US2] Add both methods to `extFlag` in `flag_ext.go` per FR-004.

## Phase 5: Polish and Validation

- [X] T009 Regenerate `godoc-current.txt` and `testdata/godoc-v3.x.txt` per FR-006.
- [X] T010 Run focused schema and nearby regression checks under the test lease, inspect formatting and diff, and compare code with `specs/001-typed-flag-schema/spec.md`.

## Dependencies and Execution Order

T001 grounds the feature. T002 and T003 establish the public contract and focused test oracle. T004 and T005 complete US1. T006 through T008 complete US2. T009 and T010 finish the local gate. All test execution requires the parent-granted lease.
