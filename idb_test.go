package gha2db

import (
	"testing"

	lib "k8s.io/test-infra/gha2db"
)

func TestInfluxDB(t *testing.T) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Do not allow to run tests in "gha" database
	if ctx.IDBDB == "gha" {
		t.Errorf("tests cannot be run on \"gha\" database")
		return
	}
}
