# Feature Specification: Typed Flag Schema Introspection

**Feature Branch**: `base 84d0da5 (isolated detached checkout)`

**Created**: 2026-09-29

**Status**: Ready for planning

**Input**: Issue #2326: expose optional SchemaTyper and SchemaItemsTyper metadata for built-in, inverse-boolean, and wrapped standard-library flags; test branches and refresh godoc snapshots.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Describe built-in accepted types (Priority: P1)

A documentation generator inspects a flag through optional interfaces to produce JSON Schema metadata without parsing a command.

**Why this priority**: The built-in flag catalog is the primary source of schema data.

**Independent Test**: Instantiate each built-in flag type, query both interfaces before parsing, and compare the returned strings with the required mapping.

**Acceptance Scenarios**:

1. **Given** a scalar built-in flag, **when** queried for its schema type, **then** it yields `boolean`, `integer`, `number`, `string`, `duration`, or `date-time` as appropriate and an empty items type.
2. **Given** a slice built-in flag, **when** queried, **then** it yields `array` plus the scalar element type.
3. **Given** a string-map built-in flag, **when** queried, **then** it yields `object` and an empty items type.
4. **Given** a generic flag with an unsupported or absent value, **when** queried, **then** unsupported metadata is empty.

---

### User Story 2 - Describe special and external flags (Priority: P2)

The same generator can inspect inverse boolean and wrapped standard-library flags without special-case casts.

**Why this priority**: These flags bypass the generic built-in implementation.

**Independent Test**: Query an inverse boolean and wrapped standard-library flags holding each supported scalar, array, object, temporal, and unknown value branch.

**Acceptance Scenarios**:

1. **Given** an inverse boolean flag, **when** queried, **then** its schema type is `boolean` and items type is empty.
2. **Given** a wrapped standard-library flag, **when** queried, **then** its getter value determines the same mapping as an equivalent built-in flag.

### Edge Cases

- Nil slices and maps retain type information and must map as array or object.
- A nil or unsupported getter result returns empty metadata.
- Arrays with unsupported element types retain `array` as the outer type and return an empty items type.
- Non-string-keyed maps cannot be represented directly as JSON objects and return an empty type.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Add optional `SchemaTyper` and `SchemaItemsTyper` interfaces without changing the existing `Flag` contract.
- **FR-002**: `SchemaType()` MUST return `boolean` for booleans, `integer` for signed and unsigned integers, `number` for floats, `string` for strings, `array` for slices, `object` for string-keyed maps, `duration` for `time.Duration`, and `date-time` for `time.Time`; otherwise it MUST return `""`.
- **FR-003**: `SchemaItemsType()` MUST return the mapped element type for slices and `""` for scalar, object, or unsupported types.
- **FR-004**: Every built-in flag through `FlagBase`, `BoolWithInverseFlag`, and wrapped standard-library `extFlag` MUST provide both methods.
- **FR-005**: Type metadata MUST be available without flag parsing and MUST NOT change parsing or help behavior.
- **FR-006**: Focused tests MUST cover built-in flag aliases, special flags, and external getter branches; public godoc snapshots MUST be refreshed.

### Key Entities

- **Flag metadata**: Optional type and item-type strings describing a flag's accepted value.
- **Getter value**: A typed value exposed by a flag implementation and used for introspection.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All built-in flag families return the specified type strings in focused tests before command parsing.
- **SC-002**: Every supported external getter branch and unknown branch is verified by focused tests.
- **SC-003**: Existing flag parsing behavior remains unchanged in targeted regression checks.
- **SC-004**: Both godoc snapshots contain the new public interfaces and match the generated public API documentation.

## Assumptions

- The `duration` and `date-time` strings are required extensions to the listed JSON Schema vocabulary.
- Named types based on scalar kinds follow their underlying kind, except `time.Duration` and `time.Time` which retain their special names.
- Generic flags expose the accepted value through their underlying getter when available.
- Existing exported optional interfaces establish the compatibility pattern for this feature.
