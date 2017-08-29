package gha2db

import (
	"fmt"
	"testing"
	"time"

	lib "k8s.io/test-infra/gha2db"
	testlib "k8s.io/test-infra/gha2db/test"
)

type MetricTestCase struct {
	setup    func() error
	metric   string
	from     time.Time
	to       time.Time
	expected [][]string
}

func TestMetrics(t *testing.T) {
	// Test cases for each metric
	ft := testlib.YMDHMS
	var testCases = []MetricTestCase{
		{
			setup:    setupReviewersMetric,
			metric:   "reviewers",
			from:     ft(2017, 7),
			to:       ft(2017, 8),
			expected: [][]string{[]string{"3"}},
		},
	}

	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Do not allow to run tests in "gha" database
	if ctx.PgDB == "gha" {
		t.Errorf("tests cannot be run on \"gha\" database")
		return
	}

	// Execute test cases
	for index, test := range testCases {
		got, err := executeMetricTestCase(&test, &ctx)
		if err != nil {
			t.Errorf("test number %d: %v", index+1, err.Error())
		}
		if !testlib.CompareStringSlices2D(test.expected, got) {
			t.Errorf("test number %d, expected %+v, got %+v", index+1, test.expected, got)
		}
	}
}

func executeMetricTestCase(test *MetricTestCase, ctx *lib.Ctx) (result [][]string, err error) {
	// Drop database if exists
	lib.DropDatabaseIfExists(ctx)

	// Create database if needed
	createdDatabase := lib.CreateDatabaseIfNeeded(ctx)
	if !createdDatabase {
		err = fmt.Errorf("failed to create database \"%s\"", ctx.PgDB)
		return
	}

	// Drop database after tests
	defer func() {
		// Drop database after tests
		lib.DropDatabaseIfExists(ctx)
	}()

	// Connect to Postgres DB
	c := lib.PgConn(ctx)
	defer c.Close()

	// Create DB structure
	lib.Structure(ctx)
	return
}

func setupReviewersMetric() (err error) {
	return
}
