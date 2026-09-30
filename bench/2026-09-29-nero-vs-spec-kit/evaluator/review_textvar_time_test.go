package cli

import (
	"flag"
	"testing"
	"time"
)

func TestReviewTextVarTime(t *testing.T) {
	fs := flag.NewFlagSet("time", flag.ContinueOnError)
	var stamp time.Time
	fs.TextVar(&stamp, "at", time.Time{}, "")
	f := &extFlag{f: fs.Lookup("at")}
	value := f.Get()
	schemaType := f.SchemaType()
	itemsType := f.SchemaItemsType()
	t.Logf("getter runtime type=%T; SchemaType=%q; SchemaItemsType=%q", value, schemaType, itemsType)
	if _, ok := value.(*time.Time); !ok {
		t.Errorf("Getter value type = %T, want *time.Time", value)
	}
	if schemaType != "date-time" {
		t.Errorf("proposed pointer-aware SchemaType = %q, want date-time", schemaType)
	}
	if itemsType != "" {
		t.Errorf("SchemaItemsType = %q, want empty", itemsType)
	}
}
