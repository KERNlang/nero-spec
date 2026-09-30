# Flag schema interface contract

```go
type SchemaTyper interface {
    SchemaType() string
}

type SchemaItemsTyper interface {
    SchemaItemsType() string
}
```

| Accepted Go value | SchemaType | SchemaItemsType |
| --- | --- | --- |
| `bool` | `boolean` | `""` |
| signed or unsigned integer | `integer` | `""` |
| `float32`, `float64` | `number` | `""` |
| `string` | `string` | `""` |
| `time.Duration` | `duration` | `""` |
| `time.Time` | `date-time` | `""` |
| slice of supported type | `array` | element mapping |
| slice of unsupported type | `array` | `""` |
| string-keyed map | `object` | `""` |
| unsupported or nil | `""` | `""` |

The interfaces remain separate and optional. A `Flag` implementer does not need either method. Introspection must work before parsing and must not mutate flag state.
