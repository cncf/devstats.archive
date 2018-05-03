package devstats

import (
	lib "devstats"
	testlib "devstats/test"
	"testing"
	"time"

	client "github.com/influxdata/influxdb/client/v2"
)

// Return array of arrays of any values from IDB result
func getIDBResult(res []client.Result) (ret [][]interface{}) {
	if len(res) < 1 || len(res[0].Series) < 1 {
		return
	}
	for _, val := range res[0].Series[0].Values {
		row := []interface{}{}
		for _, col := range val {
			row = append(row, col)
		}
		ret = append(ret, row)
	}
	return
}

// Return array of arrays of any values from IDB result
// And postprocess special time values (like now or 1st column from
// quick ranges which has current hours etc) - used for quick ranges
// skipI means that also index "skipI" should skip time now() value (only if additionalSkip is true)
func getIDBResultFiltered(res []client.Result, additionalSkip bool, skipI int) (ret [][]interface{}) {
	if len(res) < 1 || len(res[0].Series) < 1 {
		return
	}
	lastI := len(res[0].Series[0].Values) - 1
	for i, val := range res[0].Series[0].Values {
		skipPeriod := false
		if i == lastI || (additionalSkip && i == skipI) {
			skipPeriod = true
		}
		row := []interface{}{}
		lastJ := len(val) - 1
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
	if ctx.IDBDB != "dbtest" {
		t.Errorf("tests can only be run on \"dbtest\" database")
		return
	}

	// Connect to InfluxDB
	con := lib.IDBConn(&ctx)

	// Drop & create DB, ignore errors (we start with fresh DB)
	// On fatal errors, lib.QueryIDB calls os.Exit, so test will fail too
	lib.QueryIDB(con, &ctx, "drop database "+ctx.IDBDB)
	lib.QueryIDB(con, &ctx, "create database "+ctx.IDBDB)

	// Drop database and close connection at the end
	defer func() {
		// Drop database at the end of test
		lib.QueryIDB(con, &ctx, "drop database "+ctx.IDBDB)

		// Close IDB connection
		lib.FatalOnError(con.Close())
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
				[]lib.Annotation{
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
				[]lib.Annotation{
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
				[]lib.Annotation{
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
				[]lib.Annotation{
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
				[]lib.Annotation{
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
				[]lib.Annotation{
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
				[]lib.Annotation{
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
			annotations:         lib.Annotations{[]lib.Annotation{}},
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
				[]lib.Annotation{
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
				[]lib.Annotation{
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
		gotAnnotations := getIDBResult(lib.QueryIDB(con, &ctx, "select * from annotations"))
		if !testlib.CompareSlices2D(test.expectedAnnotations, gotAnnotations) {
			t.Errorf(
				"test number %d: join date: %+v\nannotations: %+v\nExpected annotations:\n%+v\n%+v\ngot.",
				index+1, test.joinDate, test.annotations, test.expectedAnnotations, gotAnnotations,
			)
		}
		// Clean up for next test
		lib.QueryIDB(con, &ctx, "delete from \"annotations\"")

		// Check Quick Ranges created
		// Results contains some time values depending on current time ..Filtered func handles this
		gotQuickRanges := getIDBResultFiltered(lib.QueryIDB(con, &ctx, "select * from quick_ranges"), test.additionalSkip, test.skipI)
		if !testlib.CompareSlices2D(test.expectedQuickRanges, gotQuickRanges) {
			t.Errorf(
				"test number %d: join date: %+v\nannotations: %+v\nExpected quick ranges:\n%+v\n%+v\ngot",
				index+1, test.joinDate, test.annotations, test.expectedQuickRanges, gotQuickRanges,
			)
		}
		// Clean up for next test
		lib.QueryIDB(con, &ctx, "delete from \"quick_ranges\"")
	}
}
