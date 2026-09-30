# Data Model

## Accepted flag value

An in-memory Go value or typed nil that identifies what a flag accepts. No persistence or lifecycle state is involved.

## Schema metadata

Two independently queried optional strings:

- `SchemaType`: scalar, array, or object type, with temporal extensions.
- `SchemaItemsType`: element type only when the accepted value is a slice.

Unknown values use the empty string. Metadata is derived on query and is never stored.
