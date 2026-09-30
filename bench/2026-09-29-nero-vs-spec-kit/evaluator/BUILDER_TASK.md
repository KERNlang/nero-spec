Implement typed flag introspection for JSON Schema generation in this Go CLI library (issue #2326).

Add two optional interfaces in `flag.go`: `SchemaTyper` with `SchemaType() string`, which reports the JSON Schema type of the value a flag accepts (`boolean`, `integer`, `number`, `string`, `array`, `object`, `duration`, or `date-time`, and `""` when no clean mapping exists); and `SchemaItemsTyper` with `SchemaItemsType() string`, which reports the element type for array-valued flags and `""` for single-value or object flags.

Implement both methods generically on `FlagBase[T, C, V]` so every built-in flag type exposes them. Also implement them on `BoolWithInverseFlag` and on `extFlag`, inspecting the wrapped standard-library flag value through `e.Get()`. Add focused tests in `flag_schema_type_test.go` for built-in flag types and `extFlag` type branches. Regenerate `godoc-current.txt` and `testdata/godoc-v3.x.txt`.

Work from the provided base checkout. Follow the repository engineering instructions. Run focused tests and a Go compile/type check before reporting completion.
