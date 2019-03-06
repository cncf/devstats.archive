package devstats

import (
	"database/sql"
	lib "devstats"
	testlib "devstats/test"
	"testing"
	"time"
)

func TestCleanUTF8(t *testing.T) {
	// Test cases
	var testCases = []struct {
		value    string
		expected string
	}{
		{value: "value", expected: "value"},
		{value: "val\x00ue", expected: "value"},
		{value: "val\u0000ue", expected: "value"},
		{value: "v\x00a\U00000000l\u0000ue", expected: "value"},
		{value: "平仮名, ひらがな", expected: "平仮名, ひらがな"},
		{value: "\u0000平仮名\x00ひらがな\U00000000", expected: "平仮名ひらがな"},
	}
	// Execute test cases
	for index, test := range testCases {
		got := lib.CleanUTF8(test.value)
		if got != test.expected {
			t.Errorf("test number %d, expected %v, got %v", index+1, test.expected, got)
		}
	}
}

func TestTruncToBytes(t *testing.T) {
	// Test cases
	var testCases = []struct {
		value       string
		n           int
		expectedStr string
		expectedLen int
	}{
		{
			value:       "value",
			n:           3,
			expectedStr: "val",
			expectedLen: 3,
		},
		{
			value:       "平仮名, ひらがな",
			n:           6,
			expectedStr: "平仮",
			expectedLen: 6,
		},
		{
			value:       "平仮名, ひらがな",
			n:           8,
			expectedStr: "平仮",
			expectedLen: 6,
		},
		{
			value:       "平仮名, ひらがな",
			n:           9,
			expectedStr: "平仮名",
			expectedLen: 9,
		},
		{
			value:       "\u0000平仮名, \x00ひら\U00000000がな",
			n:           9,
			expectedStr: "平仮名",
			expectedLen: 9,
		},
	}
	// Execute test cases
	for index, test := range testCases {
		gotStr := lib.TruncToBytes(test.value, test.n)
		if gotStr != test.expectedStr {
			t.Errorf("test number %d, expected string %v, got %v", index+1, test.expectedStr, gotStr)
		}
		gotLen := len(gotStr)
		if gotLen != test.expectedLen {
			t.Errorf("test number %d, expected length %v, got %v", index+1, test.expectedLen, gotLen)
		}
	}
}

func TestTruncStringOrNil(t *testing.T) {
	// Test cases
	sValues := []string{"value", "平仮名, ひらがな", "\u0000平仮名, \x00ひら\U00000000がな"}
	var testCases = []struct {
		value    *string
		n        int
		expected interface{}
	}{
		{
			value:    nil,
			n:        10,
			expected: nil,
		},
		{
			value:    &sValues[0],
			n:        3,
			expected: "val",
		},
		{
			value:    &sValues[1],
			n:        6,
			expected: "平仮",
		},
		{
			value:    &sValues[2],
			n:        9,
			expected: "平仮名",
		},
	}
	// Execute test cases
	for index, test := range testCases {
		got := lib.TruncStringOrNil(test.value, test.n)
		if got != test.expected {
			t.Errorf("test number %d, expected %v, got %v", index+1, test.expected, got)
		}
	}
}

func TestBoolOrNil(t *testing.T) {
	result := lib.BoolOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	val := true
	result = lib.BoolOrNil(&val)
	if result != val {
		t.Errorf("expected true, got %v", result)
	}
}

func TestNegatedBoolOrNil(t *testing.T) {
	result := lib.NegatedBoolOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	val := true
	result = lib.NegatedBoolOrNil(&val)
	expected := !val
	if result != expected {
		t.Errorf("expected %v, got %v", expected, result)
	}
}

func TestTimeOrNil(t *testing.T) {
	result := lib.TimeOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	val := time.Now()
	result = lib.TimeOrNil(&val)
	if result != val {
		t.Errorf("expected %v, got %v", val, result)
	}
}

func TestIntOrNil(t *testing.T) {
	result := lib.IntOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	val := 2
	result = lib.IntOrNil(&val)
	if result != val {
		t.Errorf("expected %v, got %v", val, result)
	}
}

func TestFirstIntOrNil(t *testing.T) {
	nn1 := 1
	nn2 := 2
	var testCases = []struct {
		array    []*int
		expected interface{}
	}{
		{array: []*int{}, expected: nil},
		{array: []*int{nil}, expected: nil},
		{array: []*int{&nn1}, expected: nn1},
		{array: []*int{nil, nil}, expected: nil},
		{array: []*int{nil, &nn1}, expected: nn1},
		{array: []*int{&nn1, nil}, expected: nn1},
		{array: []*int{&nn1, &nn2}, expected: nn1},
		{array: []*int{&nn2, &nn1}, expected: nn2},
		{array: []*int{nil, &nn2, &nn1}, expected: nn2},
	}
	// Execute test cases
	for index, test := range testCases {
		got := lib.FirstIntOrNil(test.array)
		if got != test.expected {
			t.Errorf("test number %d, expected %v, got %v", index+1, test.expected, got)
		}
	}
}

func TestStringOrNil(t *testing.T) {
	result := lib.StringOrNil(nil)
	if result != nil {
		t.Errorf("test nil case: expected <nil>, got %v", result)
	}
	val := "hello\x00 world"
	expected := "hello world"
	result = lib.StringOrNil(&val)
	if result != expected {
		t.Errorf("expected %v, got %v", val, result)
	}
}

func TestPostgres(t *testing.T) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()
	ctx.TestMode = true

	// Do not allow to run tests in "gha" database
	if ctx.PgDB != "dbtest" {
		t.Errorf("tests can only be run on \"dbtest\" database")
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
	defer func() { lib.FatalOnError(c.Close()) }()

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
	lib.FatalOnError(lib.QueryRowSQL(c, &ctx, "select an_int from test").Scan(&i))
	if i != 1 {
		t.Errorf("expected to insert 1, got %v", i)
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
	if !testlib.CompareIntSlices(gotArr, expectedArr) {
		t.Errorf("expected %v after two inserts, got %v", expectedArr, gotArr)
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
	lib.FatalOnError(tx.Rollback())

	// Get all ints from database
	gotArr = getInts(c, &ctx)

	if !testlib.CompareIntSlices(gotArr, expectedArr) {
		t.Errorf("expected %v after rollback, got %v", expectedArr, gotArr)
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
	lib.FatalOnError(tx.Commit())

	// Get all ints from database
	gotArr = getInts(c, &ctx)

	expectedArr = []int{1, 11, 31}
	if !testlib.CompareIntSlices(gotArr, expectedArr) {
		t.Errorf("expected %v after commit, got %v", expectedArr, gotArr)
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

	if !testlib.CompareIntSlices(gotArr, expectedArr) {
		t.Errorf("expected %v after insert ignore, got %v", expectedArr, gotArr)
	}
}

// getInts - gets all ints from database, sorted
func getInts(c *sql.DB, ctx *lib.Ctx) []int {
	// Get inserted values
	rows := lib.QuerySQLWithErr(c, ctx, "select an_int from test order by an_int asc")
	defer func() { lib.FatalOnError(rows.Close()) }()

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
