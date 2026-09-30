package cli

import (
	"flag"
	"reflect"
	"time"
)

func schemaTypeOf(value any) string {
	if getter, ok := value.(flag.Getter); ok {
		value = getter.Get()
	}
	return schemaTypeFromReflect(reflect.TypeOf(value))
}

func schemaItemsTypeOf(value any) string {
	if getter, ok := value.(flag.Getter); ok {
		value = getter.Get()
	}
	t := reflect.TypeOf(value)
	if t == nil || t.Kind() != reflect.Slice {
		return ""
	}
	return schemaTypeFromReflect(t.Elem())
}

func schemaTypeFromReflect(t reflect.Type) string {
	if t == nil {
		return ""
	}
	if t == reflect.TypeOf(time.Duration(0)) {
		return "duration"
	}
	if t == reflect.TypeOf(time.Time{}) {
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
	case reflect.Slice:
		return "array"
	case reflect.Map:
		if t.Key().Kind() == reflect.String {
			return "object"
		}
	}
	return ""
}
