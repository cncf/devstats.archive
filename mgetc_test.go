package devstats

import (
	lib "devstats"
	"testing"
)

func TestMgetc(t *testing.T) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Set context's Mgetc manually (don't need to repeat tests from context_test.go)
	ctx.Mgetc = "y"

	expected := "y"
	got := lib.Mgetc(&ctx)
	if got != expected {
		t.Errorf("expected %v, got %v", expected, got)
	}
}
