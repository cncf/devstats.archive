package gha2db_test

import (
	"database/sql"
	"testing"
	"time"

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
	lib.ExecSQLWithErr(
		c,
		&ctx,
		lib.CreateTable(
			"test(an_int int, a_string text, a_dt {{ts}}, primary key(an_int))",
		),
	)

	// Insert single row
	lib.ExecSQLWithErr(
		c,
		&ctx,
		"insert into test(an_int, a_string, a_dt) "+lib.NValues(3),
		lib.AnyArray{1, "string", time.Now()}...,
	)

	// Get inserted int
	i := 0
	lib.QueryRowSQL(c, &ctx, "select an_int from test").Scan(&i)
	if i != 1 {
		t.Errorf("expected 1, go %v", i)
	}

	// Insert another row
	lib.ExecSQLWithErr(
		c,
		&ctx,
		"insert into test(an_int, a_string, a_dt) "+lib.NValues(3),
		lib.AnyArray{11, "another string", time.Now()}...,
	)

	// Get all ints from database
	gotArr := getInts(c, &ctx)

	expectedArr := []int{1, 11}
	if !compareSlices(&gotArr, &expectedArr) {
		t.Errorf("expected %v, got %v", expectedArr, gotArr)
	}

	// Start transaction
	tx, err := c.Begin()
	if err != nil {
		t.Errorf(err.Error())
	}

	// Insert another row
	lib.ExecSQLTxWithErr(
		tx,
		&ctx,
		"insert into test(an_int, a_string, a_dt) "+lib.NValues(3),
		lib.AnyArray{21, "this will be rolled back", time.Now()}...,
	)

	// Rollback transaction
	tx.Rollback()

	// Get all ints from database
	gotArr = getInts(c, &ctx)

	if !compareSlices(&gotArr, &expectedArr) {
		t.Errorf("expected %v, got %v", expectedArr, gotArr)
	}

	// Start transaction
	tx, err = c.Begin()
	if err != nil {
		t.Errorf(err.Error())
	}

	// Insert another row
	lib.ExecSQLTxWithErr(
		tx,
		&ctx,
		"insert into test(an_int, a_string, a_dt) "+lib.NValues(3),
		lib.AnyArray{31, "this will be committed", time.Now()}...,
	)

	// Commit transaction
	tx.Commit()

	// Get all ints from database
	gotArr = getInts(c, &ctx)

	expectedArr = []int{1, 11, 31}
	if !compareSlices(&gotArr, &expectedArr) {
		t.Errorf("expected %v, got %v", expectedArr, gotArr)
	}

	// Insert ignore row (that violetes primary key constraint)
	lib.ExecSQLWithErr(
		c,
		&ctx,
		lib.InsertIgnore("into test(an_int, a_string, a_dt) "+lib.NValues(3)),
		lib.AnyArray{1, "conflicting key", time.Now()}...,
	)

	// Get all ints from database
	gotArr = getInts(c, &ctx)

	if !compareSlices(&gotArr, &expectedArr) {
		t.Errorf("expected %v, got %v", expectedArr, gotArr)
	}
}

// compareSlices - comparses two int slices
func compareSlices(s1 *[]int, s2 *[]int) bool {
	if len(*s1) != len(*s2) {
		return false
	}
	for index, value := range *s1 {
		if value != (*s2)[index] {
			return false
		}
	}
	return true
}

// getInts - gets all ints from database, sorted
func getInts(c *sql.DB, ctx *lib.Ctx) []int {
	// Get inserted values
	rows := lib.QuerySQLWithErr(c, ctx, "select an_int from test order by an_int asc")
	defer rows.Close()

	var (
		i   int
		arr []int
	)
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&i))
		arr = append(arr, i)
	}
	lib.FatalOnError(rows.Err())
	return arr
}
