package devstats

import (
	"database/sql"
	lib "devstats"
	testlib "devstats/test"
	"testing"
	"time"
)

// Return array of arrays of any values from TSDB result
func getTSDBResult(rows *sql.Rows) (ret [][]interface{}) {
	columns, err := rows.Columns()
	lib.FatalOnError(err)

	// Vals to hold any type as []interface{}
	vals := make([]interface{}, len(columns))
	for i := range columns {
		vals[i] = new([]byte)
	}

	for rows.Next() {
		lib.FatalOnError(rows.Scan(vals...))
		row := []interface{}{}
		for _, val := range vals {
			value := ""
			if val != nil {
				value = string(*val.(*[]byte))
			}
			row = append(row, value)
		}
		ret = append(ret, row)
	}
	lib.FatalOnError(rows.Err())
	return
}

// Return array of arrays of any values from TSDB result
// And postprocess special time values (like now or 1st column from
// quick ranges which has current hours etc) - used for quick ranges
// skipI means that also index "skipI" should skip time now() value (only if additionalSkip is true)
func getTSDBResultFiltered(rows *sql.Rows, additionalSkip bool, skipI int) (ret [][]interface{}) {
	res := getTSDBResult(rows)
	if len(res) < 1 || len(res[0]) < 1 {
		return
	}
	lastI := len(res) - 1
	lastJ := len(res[0]) - 1
	for i, val := range res {
		skipPeriod := false
		if i == lastI || (additionalSkip && i == skipI) {
			skipPeriod = true
		}
		row := []interface{}{}
		for j, col := range val {
			// This is a time column, unused, but varies every call
			// j == 0: first unused time col (related to `now`)
			// j == lastJ: last usused value, always 0
			// j == 1 && skipPeriod (last row `version - now`): `now` varies with time
			// or row specified by additionalSkip + skipI
			// Last row's date to is now which also varies every time
			if j == 0 || j == lastJ || (j == 1 && skipPeriod) {
				continue
			}
			row = append(row, col)
		}
		ret = append(ret, row)
	}
	return
}

func TestProcessAnnotations(t *testing.T) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

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

	// Connect to Postgres DB
	c := lib.PgConn(&ctx)

	// Drop database after tests
	defer func() {
		lib.FatalOnError(c.Close())
		// Drop database after tests
		lib.DropDatabaseIfExists(&ctx)
	}()

	// Test cases (they will create and close new connection inside ProcessAnnotations)
	ft := testlib.YMDHMS
	earlyDate := ft(2014)
	middleDate := ft(2016)
	lateDate := ft(2018)
	var testCases = []struct {
		annotations         lib.Annotations
		startDate           *time.Time
		joinDate            *time.Time
		expectedAnnotations [][]interface{}
		expectedQuickRanges [][]interface{}
		additionalSkip      bool
		skipI               int
	}{
		{
			annotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "release 0.0.0",
						Description: "desc 0.0.0",
						Date:        ft(2017, 2),
					},
				},
			},
			startDate: &earlyDate,
			joinDate:  &middleDate,
			expectedAnnotations: [][]interface{}{
				{"2014-01-01T00:00:00Z", "2014-01-01 - project starts", "Project start date"},
				{"2016-01-01T00:00:00Z", "2016-01-01 - joined CNCF", "CNCF join date"},
				{"2017-02-01T00:00:00Z", "desc 0.0.0", "release 0.0.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"release 0.0.0 - now", "a_0_n"},
				{"c_b;;2014-01-01 00:00:00;2016-01-01 00:00:00", "Before joining CNCF", "c_b"},
				{"Since joining CNCF", "c_n"},
			},
			additionalSkip: true,
			skipI:          7,
		},
		{
			annotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "release 0.0.0",
						Description: "desc 0.0.0",
						Date:        ft(2017, 2),
					},
				},
			},
			startDate: &earlyDate,
			joinDate:  &earlyDate,
			expectedAnnotations: [][]interface{}{
				{"2017-02-01T00:00:00Z", "desc 0.0.0", "release 0.0.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"release 0.0.0 - now", "a_0_n"},
			},
		},
		{
			annotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "release 0.0.0",
						Description: "desc 0.0.0",
						Date:        ft(2017, 2),
					},
				},
			},
			startDate: &middleDate,
			joinDate:  &earlyDate,
			expectedAnnotations: [][]interface{}{
				{"2017-02-01T00:00:00Z", "desc 0.0.0", "release 0.0.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"release 0.0.0 - now", "a_0_n"},
			},
		},
		{
			annotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "release 0.0.0",
						Description: "desc 0.0.0",
						Date:        ft(2017, 2),
					},
				},
			},
			startDate: &middleDate,
			expectedAnnotations: [][]interface{}{
				{"2016-01-01T00:00:00Z", "2016-01-01 - project starts", "Project start date"},
				{"2017-02-01T00:00:00Z", "desc 0.0.0", "release 0.0.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"release 0.0.0 - now", "a_0_n"},
			},
		},
		{
			annotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "release 0.0.0",
						Description: "desc 0.0.0",
						Date:        ft(2017, 2),
					},
				},
			},
			expectedAnnotations: [][]interface{}{
				{"2017-02-01T00:00:00Z", "desc 0.0.0", "release 0.0.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"release 0.0.0 - now", "a_0_n"},
			},
		},
		{
			joinDate: &earlyDate,
			annotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "release 0.0.0",
						Description: "desc 0.0.0",
						Date:        ft(2017, 2),
					},
				},
			},
			expectedAnnotations: [][]interface{}{
				{"2014-01-01T00:00:00Z", "2014-01-01 - joined CNCF", "CNCF join date"},
				{"2017-02-01T00:00:00Z", "desc 0.0.0", "release 0.0.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"release 0.0.0 - now", "a_0_n"},
			},
		},
		{
			joinDate: &lateDate,
			annotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "release 0.0.0",
						Description: "desc 0.0.0",
						Date:        ft(2017, 2),
					},
				},
			},
			expectedAnnotations: [][]interface{}{
				{"2017-02-01T00:00:00Z", "desc 0.0.0", "release 0.0.0"},
				{"2018-01-01T00:00:00Z", "2018-01-01 - joined CNCF", "CNCF join date"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"release 0.0.0 - now", "a_0_n"},
			},
		},
		{
			annotations:         lib.Annotations{Annotations: []lib.Annotation{}},
			expectedAnnotations: [][]interface{}{},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"Last decade", "y10"},
			},
		},
		{
			annotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "release 4.0.0",
						Description: "desc 4.0.0",
						Date:        ft(2017, 5),
					},
					{
						Name:        "release 3.0.0",
						Description: "desc 3.0.0",
						Date:        ft(2017, 4),
					},
					{
						Name:        "release 1.0.0",
						Description: "desc 1.0.0",
						Date:        ft(2017, 2),
					},
					{
						Name:        "release 0.0.0",
						Description: "desc 0.0.0",
						Date:        ft(2017, 1),
					},
					{
						Name:        "release 2.0.0",
						Description: "desc 2.0.0",
						Date:        ft(2017, 3),
					},
				},
			},
			expectedAnnotations: [][]interface{}{
				{"2017-01-01T00:00:00Z", "desc 0.0.0", "release 0.0.0"},
				{"2017-02-01T00:00:00Z", "desc 1.0.0", "release 1.0.0"},
				{"2017-03-01T00:00:00Z", "desc 2.0.0", "release 2.0.0"},
				{"2017-04-01T00:00:00Z", "desc 3.0.0", "release 3.0.0"},
				{"2017-05-01T00:00:00Z", "desc 4.0.0", "release 4.0.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"a_0_1;;2017-01-01 00:00:00;2017-02-01 00:00:00", "release 0.0.0 - release 1.0.0", "a_0_1"},
				{"a_1_2;;2017-02-01 00:00:00;2017-03-01 00:00:00", "release 1.0.0 - release 2.0.0", "a_1_2"},
				{"a_2_3;;2017-03-01 00:00:00;2017-04-01 00:00:00", "release 2.0.0 - release 3.0.0", "a_2_3"},
				{"a_3_4;;2017-04-01 00:00:00;2017-05-01 00:00:00", "release 3.0.0 - release 4.0.0", "a_3_4"},
				{"release 4.0.0 - now", "a_4_n"},
			},
		},
		{
			annotations: lib.Annotations{
				Annotations: []lib.Annotation{
					{
						Name:        "v1.0",
						Description: "desc v1.0",
						Date:        ft(2016, 1),
					},
					{
						Name:        "v6.0",
						Description: "desc v6.0",
						Date:        ft(2016, 6),
					},
					{
						Name:        "v2.0",
						Description: "desc v2.0",
						Date:        ft(2016, 2),
					},
					{
						Name:        "v4.0",
						Description: "desc v4.0",
						Date:        ft(2016, 4),
					},
					{
						Name:        "v3.0",
						Description: "desc v3.0",
						Date:        ft(2016, 3),
					},
					{
						Name:        "v5.0",
						Description: "desc v5.0",
						Date:        ft(2016, 5),
					},
				},
			},
			expectedAnnotations: [][]interface{}{
				{"2016-01-01T00:00:00Z", "desc v1.0", "v1.0"},
				{"2016-02-01T00:00:00Z", "desc v2.0", "v2.0"},
				{"2016-03-01T00:00:00Z", "desc v3.0", "v3.0"},
				{"2016-04-01T00:00:00Z", "desc v4.0", "v4.0"},
				{"2016-05-01T00:00:00Z", "desc v5.0", "v5.0"},
				{"2016-06-01T00:00:00Z", "desc v6.0", "v6.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"a_0_1;;2016-01-01 00:00:00;2016-02-01 00:00:00", "v1.0 - v2.0", "a_0_1"},
				{"a_1_2;;2016-02-01 00:00:00;2016-03-01 00:00:00", "v2.0 - v3.0", "a_1_2"},
				{"a_2_3;;2016-03-01 00:00:00;2016-04-01 00:00:00", "v3.0 - v4.0", "a_2_3"},
				{"a_3_4;;2016-04-01 00:00:00;2016-05-01 00:00:00", "v4.0 - v5.0", "a_3_4"},
				{"a_4_5;;2016-05-01 00:00:00;2016-06-01 00:00:00", "v5.0 - v6.0", "a_4_5"},
				{"v6.0 - now", "a_5_n"},
			},
		},
	}
	// Execute test cases
	for index, test := range testCases {
		// Execute annotations & quick ranges call
		lib.ProcessAnnotations(&ctx, &test.annotations, test.startDate, test.joinDate)

		// Check annotations created
		rows := lib.QuerySQLWithErr(c, &ctx, "select time, description, title from \"sannotations\" order by time asc")
		gotAnnotations := getTSDBResult(rows)
		lib.FatalOnError(rows.Close())
		if !testlib.CompareSlices2D(test.expectedAnnotations, gotAnnotations) {
			t.Errorf(
				"test number %d: join date: %+v\nannotations: %+v\nExpected annotations:\n%+v\n%+v\ngot.",
				index+1, test.joinDate, test.annotations, test.expectedAnnotations, gotAnnotations,
			)
		}

		// Clean up for next test
		lib.ExecSQLWithErr(c, &ctx, "delete from \"sannotations\"")

		// Check Quick Ranges created
		// Results contains some time values depending on current time ..Filtered func handles this
		rows = lib.QuerySQLWithErr(c, &ctx, "select time, quick_ranges_data, quick_ranges_name, quick_ranges_suffix, 0 from \"tquick_ranges\" order by time asc")
		gotQuickRanges := getTSDBResultFiltered(rows, test.additionalSkip, test.skipI)
		lib.FatalOnError(rows.Close())
		if !testlib.CompareSlices2D(test.expectedQuickRanges, gotQuickRanges) {
			t.Errorf(
				"test number %d: join date: %+v\nannotations: %+v\nExpected quick ranges:\n%+v\n%+v\ngot",
				index+1, test.joinDate, test.annotations, test.expectedQuickRanges, gotQuickRanges,
			)
		}
		// Clean up for next test
		lib.ExecSQLWithErr(c, &ctx, "delete from \"tquick_ranges\"")
	}
}
