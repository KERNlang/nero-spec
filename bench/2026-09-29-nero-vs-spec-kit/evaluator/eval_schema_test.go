package cli

import (
	"flag"
	"fmt"
	"testing"
	"time"
)

func TestEvalSchemaFlagKinds(t *testing.T) {
	tests := []struct {
		name  string
		flag  Flag
		kind  string
		items string
	}{
		{"bool", &BoolFlag{}, "boolean", ""},
		{"inverse bool", &BoolWithInverseFlag{Name: "invert"}, "boolean", ""},
		{"string", &StringFlag{}, "string", ""},
		{"int", &IntFlag{}, "integer", ""},
		{"int8", &Int8Flag{}, "integer", ""},
		{"int16", &Int16Flag{}, "integer", ""},
		{"int32", &Int32Flag{}, "integer", ""},
		{"int64", &Int64Flag{}, "integer", ""},
		{"uint", &UintFlag{}, "integer", ""},
		{"uint8", &Uint8Flag{}, "integer", ""},
		{"uint16", &Uint16Flag{}, "integer", ""},
		{"uint32", &Uint32Flag{}, "integer", ""},
		{"uint64", &Uint64Flag{}, "integer", ""},
		{"float", &FloatFlag{}, "number", ""},
		{"float32", &Float32Flag{}, "number", ""},
		{"float64", &Float64Flag{}, "number", ""},
		{"duration", &DurationFlag{}, "duration", ""},
		{"timestamp", &TimestampFlag{}, "date-time", ""},
		{"string slice", &StringSliceFlag{}, "array", "string"},
		{"int slice", &IntSliceFlag{}, "array", "integer"},
		{"int8 slice", &Int8SliceFlag{}, "array", "integer"},
		{"int16 slice", &Int16SliceFlag{}, "array", "integer"},
		{"int32 slice", &Int32SliceFlag{}, "array", "integer"},
		{"int64 slice", &Int64SliceFlag{}, "array", "integer"},
		{"uint slice", &UintSliceFlag{}, "array", "integer"},
		{"uint8 slice", &Uint8SliceFlag{}, "array", "integer"},
		{"uint16 slice", &Uint16SliceFlag{}, "array", "integer"},
		{"uint32 slice", &Uint32SliceFlag{}, "array", "integer"},
		{"uint64 slice", &Uint64SliceFlag{}, "array", "integer"},
		{"float slice", &FloatSliceFlag{}, "array", "number"},
		{"float32 slice", &Float32SliceFlag{}, "array", "number"},
		{"float64 slice", &Float64SliceFlag{}, "array", "number"},
		{"string map", &StringMapFlag{}, "object", ""},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			typeFlag, ok := tc.flag.(SchemaTyper)
			if !ok {
				t.Fatalf("%T does not implement SchemaTyper", tc.flag)
			}
			itemsFlag, ok := tc.flag.(SchemaItemsTyper)
			if !ok {
				t.Fatalf("%T does not implement SchemaItemsTyper", tc.flag)
			}
			if got := typeFlag.SchemaType(); got != tc.kind {
				t.Errorf("SchemaType() = %q, want %q", got, tc.kind)
			}
			if got := itemsFlag.SchemaItemsType(); got != tc.items {
				t.Errorf("SchemaItemsType() = %q, want %q", got, tc.items)
			}
		})
	}
}

func TestEvalGenericFlagNilSchemaItems(t *testing.T) {
	var f Flag = &GenericFlag{Name: "custom"}
	typeFlag, ok := f.(SchemaTyper)
	if !ok {
		t.Fatal("GenericFlag does not implement SchemaTyper")
	}
	itemsFlag, ok := f.(SchemaItemsTyper)
	if !ok {
		t.Fatal("GenericFlag does not implement SchemaItemsTyper")
	}
	if got := typeFlag.SchemaType(); got != "" {
		t.Errorf("SchemaType() = %q, want empty", got)
	}
	if got := itemsFlag.SchemaItemsType(); got != "" {
		t.Errorf("SchemaItemsType() = %q, want empty", got)
	}
}

func TestEvalExternalFlagKinds(t *testing.T) {
	fs := flag.NewFlagSet("schema", flag.ContinueOnError)
	fs.Bool("bool", false, "")
	fs.Int("int", 0, "")
	fs.Int64("int64", 0, "")
	fs.Uint("uint", 0, "")
	fs.Uint64("uint64", 0, "")
	fs.Float64("float64", 0, "")
	fs.String("string", "", "")
	fs.Duration("duration", time.Second, "")
	tests := []struct {
		name string
		kind string
	}{
		{"bool", "boolean"},
		{"int", "integer"},
		{"int64", "integer"},
		{"uint", "integer"},
		{"uint64", "integer"},
		{"float64", "number"},
		{"string", "string"},
		{"duration", "duration"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			checkEvalExternalFlag(t, &extFlag{f: fs.Lookup(tc.name)}, tc.kind)
		})
	}
	for _, tc := range []struct {
		name  string
		value any
		kind  string
	}{
		{"date-time", time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC), "date-time"},
		{"unknown", make(chan int), ""},
	} {
		t.Run(tc.name, func(t *testing.T) {
			f := &flag.Flag{Name: tc.name, Value: &evalGetter{value: tc.value}}
			checkEvalExternalFlag(t, &extFlag{f: f}, tc.kind)
		})
	}
}

func checkEvalExternalFlag(t *testing.T, f Flag, kind string) {
	t.Helper()
	typeFlag, ok := f.(SchemaTyper)
	if !ok {
		t.Fatal("external flag does not implement SchemaTyper")
	}
	itemsFlag, ok := f.(SchemaItemsTyper)
	if !ok {
		t.Fatal("external flag does not implement SchemaItemsTyper")
	}
	if got := typeFlag.SchemaType(); got != kind {
		t.Errorf("SchemaType() = %q, want %q", got, kind)
	}
	if got := itemsFlag.SchemaItemsType(); got != "" {
		t.Errorf("SchemaItemsType() = %q, want empty", got)
	}
}

type evalGetter struct {
	value any
}

func (g *evalGetter) String() string   { return fmt.Sprint(g.value) }
func (g *evalGetter) Set(string) error { return nil }
func (g *evalGetter) Get() any         { return g.value }
