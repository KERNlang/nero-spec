# Research

- `FlagBase[T,C,V]` is the shared implementation for all ordinary built-in flags. Its `Get()` returns the accepted typed value before or after parsing. `GenericFlag` can hold a custom `Value`; inspect that value's getter once.
- `BoolWithInverseFlag` has a separate implementation and is always boolean.
- `extFlag.Get()` exposes the standard-library `flag.Getter` result, so its mapping can share the helper.
- Map `time.Duration` and `time.Time` before their underlying integer/struct kinds. Use `reflect.Kind` for scalar aliases, slices, and string-key maps. Unknown structs, pointers, interfaces, and non-string-key maps have no clean mapping.
- `scripts/build.go` generates `godoc-current.txt` with `go doc -all`; `testdata/godoc-v3.x.txt` is the reference snapshot. Generation is documentation work, not a test run.
- No unresolved specification ambiguity materially affects implementation. No external research or network access is needed.
