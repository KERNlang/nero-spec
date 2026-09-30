package cli

import (
	"flag"
	"testing"
)

func TestReviewExternalNonGetter(t *testing.T) {
	fs := flag.NewFlagSet("external", flag.ContinueOnError)
	fs.Func("callback", "", func(string) error { return nil })
	wrapped := fs.Lookup("callback")
	if _, ok := wrapped.Value.(flag.Getter); ok {
		t.Fatal("flag.Func unexpectedly implements flag.Getter")
	}
	f := &extFlag{f: wrapped}
	for _, tc := range []struct {
		name   string
		method func() string
	}{
		{"SchemaType", f.SchemaType},
		{"SchemaItemsType", f.SchemaItemsType},
	} {
		t.Run(tc.name, func(t *testing.T) {
			defer func() {
				if value := recover(); value != nil {
					t.Errorf("panic: %v", value)
				}
			}()
			if got := tc.method(); got != "" {
				t.Errorf("got %q, want empty schema type", got)
			}
		})
	}
}
