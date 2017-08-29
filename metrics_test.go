package gha2db

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"strconv"
	"strings"
	"testing"
	"time"

	lib "k8s.io/test-infra/gha2db"
	testlib "k8s.io/test-infra/gha2db/test"
)

// MetricTestCase - used to test single metric
// setup is called to create database entries for metric to return results
// metric - psql_metrics/{{metric}}.sql file is used to run metric, inside file {{from}} and {{to}} are replaced with from, to
// from, to - used as data range when calling metric
// expected - we're expecting this result from metric, it can either be a single row with single column numeric value
// or multiple rows, each containing metric name and its numeric value
type MetricTestCase struct {
	setup    func(*sql.DB, *lib.Ctx) error
	metric   string
	from     time.Time
	to       time.Time
	expected [][]interface{}
}

// Tests all metrics
func TestMetrics(t *testing.T) {
	// Test cases for each metric
	ft := testlib.YMDHMS

	// Please add new cases here
	// And their setup function at the bottom of this file
	var testCases = []MetricTestCase{
		{
			setup:    setupReviewersMetric,
			metric:   "reviewers",
			from:     ft(2017, 7, 9),
			to:       ft(2017, 7, 25),
			expected: [][]interface{}{[]interface{}{6}},
		},
		{
			setup:    setupReviewersMetric,
			metric:   "reviewers",
			from:     ft(2017, 6, 1),
			to:       ft(2017, 7, 12, 23),
			expected: [][]interface{}{[]interface{}{3}},
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
		if !testlib.CompareSlices2D(test.expected, got) {
			t.Errorf("test number %d, expected %+v, got %+v", index+1, test.expected, got)
		}
	}
}

// This executes test of single metric
// All metric data is defined in "testMetric" argument
// Singel metric test is dropping & creating database from scratch (to avoid junky database)
// It also creates full DB structure - without indexes - they're not needed in
// small databases - like the ones created by test covergae tools
func executeMetricTestCase(testMetric *MetricTestCase, ctx *lib.Ctx) (result [][]interface{}, err error) {
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

	// Execute metrics setup function
	err = testMetric.setup(c, ctx)
	if err != nil {
		return
	}

	// Execute metric and get its results
	result, err = executeMetric(c, ctx, testMetric.metric, testMetric.from, testMetric.to)

	// We're after succesfull setup
	return
}

// execute metric psql_metrics/{{metric}}.sql with {{from}} and {{to}} replaced by from/YMDHMS, to/YMDHMS
// end result slice of slices of any type
func executeMetric(c *sql.DB, ctx *lib.Ctx, metric string, from, to time.Time) (result [][]interface{}, err error) {
	// Metric file name
	sqlFile := fmt.Sprintf("psql_metrics/%s.sql", metric)

	// Read and transform SQL file.
	bytes, err := ioutil.ReadFile(sqlFile)
	if err != nil {
		return
	}
	sqlQuery := string(bytes)
	sqlQuery = strings.Replace(sqlQuery, "{{from}}", lib.ToYMDHMSDate(from), -1)
	sqlQuery = strings.Replace(sqlQuery, "{{to}}", lib.ToYMDHMSDate(to), -1)

	// Execute SQL
	rows := lib.QuerySQLWithErr(c, ctx, sqlQuery)
	defer rows.Close()

	// Now unknown rows, with unknown types
	columns, err := rows.Columns()
	if err != nil {
		return
	}

	// Vals to hold any type as []interface{}
	vals := make([]interface{}, len(columns))
	for i := range columns {
		vals[i] = new(sql.RawBytes)
	}

	// Get results into slices of slices of any type
	var results [][]interface{}
	for rows.Next() {
		err = rows.Scan(vals...)
		if err != nil {
			return
		}
		// We need to iterate row and get columns types
		rowSlice := []interface{}{}
		for _, val := range vals {
			var value interface{}
			if val != nil {
				value = string(*val.(*sql.RawBytes))
				iValue, err := strconv.Atoi(value.(string))
				if err == nil {
					value = iValue
				}
			}
			rowSlice = append(rowSlice, value)
		}
		results = append(results, rowSlice)
	}
	err = rows.Err()
	if err != nil {
		return
	}
	result = results
	return
}

// Add event
func addEvent(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 9 {
		err = fmt.Errorf("addEvent: expects 9 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_events("+
			"id, type, actor_id, repo_id, public, created_at, "+
			"actor_login, repo_name, org_id) "+lib.NValues(9),
		args...,
	)
	return
}

// Add issue event label
func addIssueEventLabel(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 5 {
		err = fmt.Errorf("addIssueEventLabel: expects 5 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_issues_events_labels("+
			"issue_id, event_id, label_id, label_name, created_at"+
			") "+lib.NValues(5),
		args...,
	)
	return
}

// Add text
func addText(con *sql.DB, ctx *lib.Ctx, args ...interface{}) (err error) {
	if len(args) != 3 {
		err = fmt.Errorf("addText: expects 3 variadic parameters")
		return
	}
	_, err = lib.ExecSQL(
		con,
		ctx,
		"insert into gha_texts("+
			"event_id, body, created_at"+
			") "+lib.NValues(3),
		args...,
	)
	return
}

func setupReviewersMetric(con *sql.DB, ctx *lib.Ctx) (err error) {
	ft := testlib.YMDHMS

	// Events to add
	events := [][]interface{}{
		[]interface{}{1, "T", 1, 1, true, ft(2017, 7, 10), "Actor 1", "Repo 1", 1},
		[]interface{}{2, "T", 2, 2, true, ft(2017, 7, 11), "Actor 2", "Repo 2", 1},
		[]interface{}{3, "T", 3, 1, true, ft(2017, 7, 12), "Actor 3", "Repo 1", 1},
		[]interface{}{4, "T", 4, 3, true, ft(2017, 7, 13), "Actor 4", "Repo 3", 2},
		[]interface{}{5, "T", 5, 2, true, ft(2017, 7, 14), "Actor 5", "Repo 2", 1},
		[]interface{}{6, "T", 5, 2, true, ft(2017, 7, 15), "Actor 5", "Repo 2", 1},
		[]interface{}{7, "T", 3, 2, true, ft(2017, 7, 16), "Actor 5", "Repo 2", 1},
		[]interface{}{8, "T", 6, 4, true, ft(2017, 7, 17), "Actor 6", "Repo 4", 2},
		[]interface{}{9, "T", 7, 5, true, ft(2017, 7, 18), "Actor 7", "Repo 5", nil},
		[]interface{}{10, "T", 8, 5, true, ft(2017, 7, 19), "Actor 8", "Repo 5", nil},
		[]interface{}{11, "T", 9, 5, true, ft(2017, 7, 20), "Actor 9", "Repo 5", nil},
		[]interface{}{12, "T", 9, 5, true, ft(2017, 8, 10), "Actor X", "Repo 5", nil},
	}

	// Issue Event Labels to add
	iels := [][]interface{}{
		[]interface{}{1, 1, 1, "LGTM", ft(2017, 7, 10)},
		[]interface{}{2, 2, 2, "lgtm", ft(2017, 7, 11)},
		[]interface{}{5, 5, 5, "LGtM", ft(2017, 7, 14)},
		[]interface{}{6, 6, 6, "lgTm", ft(2017, 7, 15)},
		[]interface{}{6, 9, 1, "LGTM", ft(2017, 7, 18)}, // Not counted because it belongs to issue_id (6) which received LGTM in previous line
		[]interface{}{10, 10, 10, "other", ft(2017, 7, 19)},
		[]interface{}{12, 12, 1, "LGTM", ft(2017, 8, 10)}, // Out of date range
	}

	// Texts to add
	texts := [][]interface{}{
		[]interface{}{3, "/lgtm", ft(2017, 7, 12)},
		[]interface{}{4, " /LGTM ", ft(2017, 7, 13)},
		[]interface{}{7, " /LGTM ", ft(2017, 7, 16)},
		[]interface{}{8, "\t/LGtm\n", ft(2017, 7, 17)},
		[]interface{}{11, "/LGTM with additional text", ft(2017, 7, 20)}, // additional text causes this line to be skipped
	}

	// Add events
	for _, event := range events {
		err = addEvent(con, ctx, event...)
		if err != nil {
			return
		}
	}

	// Add issue event labels
	for _, iel := range iels {
		err = addIssueEventLabel(con, ctx, iel...)
		if err != nil {
			return
		}
	}

	// Add texts
	for _, text := range texts {
		err = addText(con, ctx, text...)
		if err != nil {
			return
		}
	}

	return
}
