package cli

import (
	"flag"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

var (
	_ SchemaTyper      = (*BoolFlag)(nil)
	_ SchemaItemsTyper = (*BoolFlag)(nil)
	_ SchemaTyper      = (*FlagBase[int, IntegerConfig, intValue[int]])(nil)
	_ SchemaItemsTyper = (*FlagBase[int, IntegerConfig, intValue[int]])(nil)
	_ SchemaTyper      = (*BoolWithInverseFlag)(nil)
	_ SchemaItemsTyper = (*BoolWithInverseFlag)(nil)
	_ SchemaTyper      = (*extFlag)(nil)
	_ SchemaItemsTyper = (*extFlag)(nil)
)

type schemaGetterValue struct {
	value any
}

func (v *schemaGetterValue) String() string   { return "" }
func (v *schemaGetterValue) Set(string) error { return nil }
func (v *schemaGetterValue) Get() any         { return v.value }

type schemaNoGetterValue struct{}

func (*schemaNoGetterValue) String() string   { return "" }
func (*schemaNoGetterValue) Set(string) error { return nil }

func TestSchemaTypeBuiltins(t *testing.T) {
	tests := []struct {
		name     string
		value    any
		typeName string
		items    string
	}{
		{"scalars/bool", &BoolFlag{}, "boolean", ""},
		{"scalars/inverse_bool", &BoolWithInverseFlag{}, "boolean", ""},
		{"scalars/int", &IntFlag{}, "integer", ""},
		{"scalars/int8", &Int8Flag{}, "integer", ""},
		{"scalars/int16", &Int16Flag{}, "integer", ""},
		{"scalars/int32", &Int32Flag{}, "integer", ""},
		{"scalars/int64", &Int64Flag{}, "integer", ""},
		{"scalars/uint", &UintFlag{}, "integer", ""},
		{"scalars/uint8", &Uint8Flag{}, "integer", ""},
		{"scalars/uint16", &Uint16Flag{}, "integer", ""},
		{"scalars/uint32", &Uint32Flag{}, "integer", ""},
		{"scalars/uint64", &Uint64Flag{}, "integer", ""},
		{"scalars/float", &FloatFlag{}, "number", ""},
		{"scalars/float32", &Float32Flag{}, "number", ""},
		{"scalars/float64", &Float64Flag{}, "number", ""},
		{"scalars/string", &StringFlag{}, "string", ""},
		{"temporal/duration", &DurationFlag{}, "duration", ""},
		{"temporal/timestamp", &TimestampFlag{}, "date-time", ""},
		{"arrays/int", &IntSliceFlag{}, "array", "integer"},
		{"arrays/int8", &Int8SliceFlag{}, "array", "integer"},
		{"arrays/int16", &Int16SliceFlag{}, "array", "integer"},
		{"arrays/int32", &Int32SliceFlag{}, "array", "integer"},
		{"arrays/int64", &Int64SliceFlag{}, "array", "integer"},
		{"arrays/uint", &UintSliceFlag{}, "array", "integer"},
		{"arrays/uint8", &Uint8SliceFlag{}, "array", "integer"},
		{"arrays/uint16", &Uint16SliceFlag{}, "array", "integer"},
		{"arrays/uint32", &Uint32SliceFlag{}, "array", "integer"},
		{"arrays/uint64", &Uint64SliceFlag{}, "array", "integer"},
		{"arrays/float", &FloatSliceFlag{}, "array", "number"},
		{"arrays/float32", &Float32SliceFlag{}, "array", "number"},
		{"arrays/float64", &Float64SliceFlag{}, "array", "number"},
		{"arrays/string_nil", &StringSliceFlag{}, "array", "string"},
		{"arrays/string_empty", &StringSliceFlag{Value: []string{}}, "array", "string"},
		{"object/string_map_nil", &StringMapFlag{}, "object", ""},
	}

	for _, tt := range tests {
		ac := "AC-1"
		if strings.HasPrefix(tt.name, "arrays/") || strings.HasPrefix(tt.name, "object/") {
			ac = "AC-2"
		}
		t.Run(ac+"/"+tt.name, func(t *testing.T) {
			st, ok := tt.value.(SchemaTyper)
			require.True(t, ok)
			sit, ok := tt.value.(SchemaItemsTyper)
			require.True(t, ok)
			require.Equal(t, tt.typeName, st.SchemaType())
			require.Equal(t, tt.items, sit.SchemaItemsType())
		})
	}
}

func TestSchemaTypeBuiltinsDestinationAC1(t *testing.T) {
	t.Run("AC-1", func(t *testing.T) {
		var destination string
		f := &StringFlag{Destination: &destination}
		require.Equal(t, "string", f.SchemaType())
		require.Empty(t, f.SchemaItemsType())
		require.NoError(t, f.PreParse())
		require.Equal(t, "string", f.SchemaType())
		require.Empty(t, f.SchemaItemsType())
	})
}

func TestSchemaTypeExtFlag(t *testing.T) {
	fs := flag.NewFlagSet("schema", flag.ContinueOnError)
	fs.Bool("bool", false, "")
	fs.Int("int", 0, "")
	fs.Int64("int64", 0, "")
	fs.Uint("uint", 0, "")
	fs.Uint64("uint64", 0, "")
	fs.Float64("float64", 0, "")
	fs.String("string", "", "")
	fs.Duration("duration", 0, "")

	for _, tt := range []struct {
		name string
		want string
	}{
		{"bool", "boolean"},
		{"int", "integer"},
		{"int64", "integer"},
		{"uint", "integer"},
		{"uint64", "integer"},
		{"float64", "number"},
		{"string", "string"},
		{"duration", "duration"},
	} {
		t.Run("AC-3/scalars/"+tt.name, func(t *testing.T) {
			e := &extFlag{f: fs.Lookup(tt.name)}
			require.Equal(t, tt.want, e.SchemaType())
			require.Empty(t, e.SchemaItemsType())
		})
	}

	for _, tt := range []struct {
		name      string
		value     any
		wantType  string
		wantItems string
	}{
		{"collections_and_unknown/nil_slice", []uint64(nil), "array", "integer"},
		{"collections_and_unknown/empty_slice", []string{}, "array", "string"},
		{"collections_and_unknown/array", [2]float64{}, "array", "number"},
		{"collections_and_unknown/map", map[string]string(nil), "object", ""},
		{"collections_and_unknown/time", time.Time{}, "date-time", ""},
		{"collections_and_unknown/opaque", struct{}{}, "", ""},
		{"collections_and_unknown/nil", nil, "", ""},
	} {
		t.Run("AC-3/"+tt.name, func(t *testing.T) {
			e := &extFlag{f: &flag.Flag{Value: &schemaGetterValue{value: tt.value}}}
			require.Equal(t, tt.wantType, e.SchemaType())
			require.Equal(t, tt.wantItems, e.SchemaItemsType())
		})
	}

	t.Run("AC-3/collections_and_unknown/non_getter", func(t *testing.T) {
		e := &extFlag{f: &flag.Flag{Value: &schemaNoGetterValue{}}}
		require.Empty(t, e.SchemaType())
		require.Empty(t, e.SchemaItemsType())
	})
}

func TestSchemaTypeOptionalAndLegacyAC4(t *testing.T) {
	t.Run("AC-4", func(t *testing.T) {
		var custom Flag = &nodocFlag{}
		_, hasType := custom.(SchemaTyper)
		_, hasItems := custom.(SchemaItemsTyper)
		require.False(t, hasType)
		require.False(t, hasItems)

		inverse := &BoolWithInverseFlag{}
		require.Equal(t, "bool", inverse.TypeName())
		require.Equal(t, "boolean", inverse.SchemaType())

		generic := &GenericFlag{Value: &schemaGetterValue{value: []int{1}}}
		require.Empty(t, generic.SchemaType())
		require.Empty(t, generic.SchemaItemsType())
		require.NoError(t, generic.PreParse())
		require.Empty(t, generic.SchemaType())
		require.Empty(t, generic.SchemaItemsType())
	})
}
