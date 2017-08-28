package gha2db_test

import (
	"testing"

	lib "k8s.io/test-infra/gha2db"
)

func TestPostgres(t *testing.T) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Do not allow to run tests in "gha" database
	if ctx.PgDB == "gha" {
		t.Errorf("tests cannot be run on \"gha\" database")
		return
	}

	// Drop database if exists
	lib.DropDatabaseIfExists(&ctx)

	// Create database if needed
	createdDatabase := lib.CreateDatabaseIfNeeded(&ctx)
	if !createdDatabase {
		t.Errorf("failed to create database \"%s\"", ctx.PgDB)
	}

	// Drop database after tests
	defer func() {
		// Drop database after tests
		lib.DropDatabaseIfExists(&ctx)
	}()

	// Connect to Postgres DB
	c := lib.PgConn(&ctx)
	defer c.Close()

	// Create example table
	lib.ExecSQLWithErr(c, &ctx, "create table test(an_int int, a_string text)")
}
