package cli

import (
	"flag"
	"fmt"
	"testing"
	"time"
)

type schemaTestGetter struct {
	value any
}

func (g schemaTestGetter) String() string   { return fmt.Sprint(g.value) }
func (g schemaTestGetter) Set(string) error { return nil }
func (g schemaTestGetter) Get() any         { return g.value }

func checkSchemaTypes(t *testing.T, f Flag, wantType, wantItems string) {
	t.Helper()
	st, ok := f.(SchemaTyper)
	if !ok {
		t.Fatalf("%T does not implement SchemaTyper", f)
	}
	it, ok := f.(SchemaItemsTyper)
	if !ok {
		t.Fatalf("%T does not implement SchemaItemsTyper", f)
	}
	if got := st.SchemaType(); got != wantType {
		t.Errorf("SchemaType() = %q, want %q", got, wantType)
	}
	if got := it.SchemaItemsType(); got != wantItems {
		t.Errorf("SchemaItemsType() = %q, want %q", got, wantItems)
	}
}

func TestFlagSchemaTypeBuiltins(t *testing.T) {
	cases := []struct {
		name, schemaType, itemsType string
		flag                        Flag
	}{
		{"bool", "boolean", "", &BoolFlag{}},
		{"int", "integer", "", &IntFlag{}},
		{"int8", "integer", "", &Int8Flag{}},
		{"int16", "integer", "", &Int16Flag{}},
		{"int32", "integer", "", &Int32Flag{}},
		{"int64", "integer", "", &Int64Flag{}},
		{"uint", "integer", "", &UintFlag{}},
		{"uint8", "integer", "", &Uint8Flag{}},
		{"uint16", "integer", "", &Uint16Flag{}},
		{"uint32", "integer", "", &Uint32Flag{}},
		{"uint64", "integer", "", &Uint64Flag{}},
		{"float", "number", "", &FloatFlag{}},
		{"float32", "number", "", &Float32Flag{}},
		{"float64", "number", "", &Float64Flag{}},
		{"string", "string", "", &StringFlag{}},
		{"duration", "duration", "", &DurationFlag{}},
		{"timestamp", "date-time", "", &TimestampFlag{}},
		{"int-slice", "array", "integer", &IntSliceFlag{}},
		{"int8-slice", "array", "integer", &Int8SliceFlag{}},
		{"int16-slice", "array", "integer", &Int16SliceFlag{}},
		{"int32-slice", "array", "integer", &Int32SliceFlag{}},
		{"int64-slice", "array", "integer", &Int64SliceFlag{}},
		{"uint-slice", "array", "integer", &UintSliceFlag{}},
		{"uint8-slice", "array", "integer", &Uint8SliceFlag{}},
		{"uint16-slice", "array", "integer", &Uint16SliceFlag{}},
		{"uint32-slice", "array", "integer", &Uint32SliceFlag{}},
		{"uint64-slice", "array", "integer", &Uint64SliceFlag{}},
		{"float-slice", "array", "number", &FloatSliceFlag{}},
		{"float32-slice", "array", "number", &Float32SliceFlag{}},
		{"float64-slice", "array", "number", &Float64SliceFlag{}},
		{"string-slice", "array", "string", &StringSliceFlag{}},
		{"string-map", "object", "", &StringMapFlag{}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			checkSchemaTypes(t, tc.flag, tc.schemaType, tc.itemsType)
		})
	}
}

func TestFlagSchemaTypeUnknown(t *testing.T) {
	cases := []struct {
		name, schemaType, itemsType string
		value                       any
	}{
		{"nil", "", "", nil},
		{"bool", "boolean", "", true},
		{"slice", "array", "integer", []int(nil)},
		{"map", "object", "", map[string]int(nil)},
		{"unknown-struct", "", "", struct{}{}},
		{"unknown-pointer", "", "", new(int)},
		{"unknown-slice-item", "array", "", []struct{}{}},
		{"non-string-map-key", "", "", map[int]string{}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			checkSchemaTypes(t, &GenericFlag{Value: schemaTestGetter{value: tc.value}}, tc.schemaType, tc.itemsType)
		})
	}
}

func TestFlagSchemaTypeSpecial(t *testing.T) {
	checkSchemaTypes(t, &BoolWithInverseFlag{}, "boolean", "")
}

func TestFlagSchemaTypeExternal(t *testing.T) {
	standard := flag.NewFlagSet("schema", flag.ContinueOnError)
	standard.Bool("bool", false, "")
	standard.Int("int", 0, "")
	standard.Uint("uint", 0, "")
	standard.Float64("float", 0, "")
	standard.String("string", "", "")
	standard.Duration("duration", 0, "")
	standard.Func("func", "", func(string) error { return nil })
	standard.VisitAll(func(f *flag.Flag) {
		want := map[string]string{
			"bool": "boolean", "int": "integer", "uint": "integer",
			"float": "number", "string": "string", "duration": "duration", "func": "",
		}[f.Name]
		t.Run("standard-"+f.Name, func(t *testing.T) {
			checkSchemaTypes(t, &extFlag{f: f}, want, "")
		})
	})
	cases := []struct {
		name, schemaType, itemsType string
		value                       any
	}{
		{"time", "date-time", "", time.Time{}},
		{"array-string", "array", "string", []string(nil)},
		{"array-duration", "array", "duration", []time.Duration{}},
		{"array-time", "array", "date-time", []time.Time{}},
		{"array-unknown-item", "array", "", []struct{}{}},
		{"object", "object", "", map[string]string(nil)},
		{"non-string-map-key", "", "", map[int]string{}},
		{"unknown-struct", "", "", struct{}{}},
		{"unknown-pointer", "", "", new(int)},
		{"nil", "", "", nil},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			f := &extFlag{f: &flag.Flag{Value: schemaTestGetter{value: tc.value}}}
			checkSchemaTypes(t, f, tc.schemaType, tc.itemsType)
		})
	}
}
