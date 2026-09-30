package cli

import (
	"reflect"
	"time"
)

var (
	durationSchemaType  = reflect.TypeOf(time.Duration(0))
	timestampSchemaType = reflect.TypeOf(time.Time{})
)

func schemaTypeFor(t reflect.Type) string {
	if t == nil {
		return ""
	}
	if t == durationSchemaType {
		return "duration"
	}
	if t == timestampSchemaType {
		return "date-time"
	}

	switch t.Kind() {
	case reflect.Bool:
		return "boolean"
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64,
		reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		return "integer"
	case reflect.Float32, reflect.Float64:
		return "number"
	case reflect.String:
		return "string"
	case reflect.Array, reflect.Slice:
		return "array"
	case reflect.Map:
		if t.Key().Kind() == reflect.String {
			return "object"
		}
	}
	return ""
}

func schemaItemsTypeFor(t reflect.Type) string {
	if t == nil {
		return ""
	}
	if t.Kind() != reflect.Array && t.Kind() != reflect.Slice {
		return ""
	}
	return schemaTypeFor(t.Elem())
}
