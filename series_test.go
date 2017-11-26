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
// quick ranges which has cuurent hours etc) - used for quick ranges
func getIDBResultFiltered(res []client.Result) (ret [][]interface{}) {
	if len(res) < 1 || len(res[0].Series) < 1 {
		return
	}
	lastI := len(res[0].Series[0].Values) - 1
	lastPeriod := false
	for i, val := range res[0].Series[0].Values {
		if i == lastI {
			lastPeriod = true
		}
		row := []interface{}{}
		lastJ := len(val) - 1
		for j, col := range val {
			// This is a time column, unused, but varies every call
			// j == 0: first unused time col (related to `now`)
			// j == lastJ: last usused value, always 0
			// j == 1 && lastPeriod (last row `version - now`): `now` varies with time
			// Last row's date to is now which also varies every time
			if j == 0 || j == lastJ || (j == 1 && lastPeriod) {
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
		con.Close()
	}()

	// Test cases (they will create and close new connection inside ProcessAnnotations)
	ft := testlib.YMDHMS
	var testCases = []struct {
		annotations         lib.Annotations
		dt                  time.Time
		expectedAnnotations [][]interface{}
		expectedQuickRanges [][]interface{}
	}{
		{
			annotations: lib.Annotations{
				[]lib.Annotation{
					{
						Title:       "release 0.0.0",
						Description: "description 0.0.0",
						SeriesName:  "annotations",
						Date:        ft(2017, 2),
					},
				},
			},
			dt: ft(2017),
			expectedAnnotations: [][]interface{}{
				{"2017-02-01T00:00:00Z", "description 0.0.0", "release 0.0.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"release 0.0.0 - now", "anno_0_now"},
			},
		},
		{
			annotations: lib.Annotations{
				[]lib.Annotation{
					{
						Title:       "release 0.0.0",
						Description: "description 0.0.0",
						SeriesName:  "annotations",
						Date:        ft(2017, 2),
					},
				},
			},
			dt:                  ft(2017, 3),
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
			annotations:         lib.Annotations{[]lib.Annotation{}},
			dt:                  ft(2017, 3),
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
						Title:       "release 4.0.0",
						Description: "description 4.0.0",
						SeriesName:  "annotations",
						Date:        ft(2017, 5),
					},
					{
						Title:       "release 3.0.0",
						Description: "description 3.0.0",
						SeriesName:  "annotations",
						Date:        ft(2017, 4),
					},
					{
						Title:       "release 1.0.0",
						Description: "description 1.0.0",
						SeriesName:  "annotations",
						Date:        ft(2017, 2),
					},
					{
						Title:       "release 0.0.0",
						Description: "description 0.0.0",
						SeriesName:  "annotations",
						Date:        ft(2017, 1),
					},
					{
						Title:       "release 2.0.0",
						Description: "description 2.0.0",
						SeriesName:  "annotations",
						Date:        ft(2017, 3),
					},
				},
			},
			dt: ft(2017, 1, 19),
			expectedAnnotations: [][]interface{}{
				{"2017-02-01T00:00:00Z", "description 1.0.0", "release 1.0.0"},
				{"2017-03-01T00:00:00Z", "description 2.0.0", "release 2.0.0"},
				{"2017-04-01T00:00:00Z", "description 3.0.0", "release 3.0.0"},
				{"2017-05-01T00:00:00Z", "description 4.0.0", "release 4.0.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"anno_1_2;;2017-02-01 00:00:00;2017-03-01 00:00:00", "release 1.0.0 - release 2.0.0", "anno_1_2"},
				{"anno_2_3;;2017-03-01 00:00:00;2017-04-01 00:00:00", "release 2.0.0 - release 3.0.0", "anno_2_3"},
				{"anno_3_4;;2017-04-01 00:00:00;2017-05-01 00:00:00", "release 3.0.0 - release 4.0.0", "anno_3_4"},
				{"release 4.0.0 - now", "anno_4_now"},
			},
		},
		{
			annotations: lib.Annotations{
				[]lib.Annotation{
					{
						Title:       "v1.0",
						Description: "Release v1.0",
						SeriesName:  "annotations",
						Date:        ft(2016, 1),
					},
					{
						Title:       "v6.0",
						Description: "Release v6.0",
						SeriesName:  "annotations",
						Date:        ft(2016, 6),
					},
					{
						Title:       "v2.0",
						Description: "Release v2.0",
						SeriesName:  "annotations",
						Date:        ft(2016, 2),
					},
					{
						Title:       "v4.0",
						Description: "Release v4.0",
						SeriesName:  "annotations",
						Date:        ft(2016, 4),
					},
					{
						Title:       "v3.0",
						Description: "Release v3.0",
						SeriesName:  "annotations",
						Date:        ft(2016, 3),
					},
					{
						Title:       "v5.0",
						Description: "Release v5.0",
						SeriesName:  "annotations",
						Date:        ft(2016, 5),
					},
				},
			},
			dt: ft(2000),
			expectedAnnotations: [][]interface{}{
				{"2016-01-01T00:00:00Z", "Release v1.0", "v1.0"},
				{"2016-02-01T00:00:00Z", "Release v2.0", "v2.0"},
				{"2016-03-01T00:00:00Z", "Release v3.0", "v3.0"},
				{"2016-04-01T00:00:00Z", "Release v4.0", "v4.0"},
				{"2016-05-01T00:00:00Z", "Release v5.0", "v5.0"},
				{"2016-06-01T00:00:00Z", "Release v6.0", "v6.0"},
			},
			expectedQuickRanges: [][]interface{}{
				{"d;1 day;;", "Last day", "d"},
				{"w;1 week;;", "Last week", "w"},
				{"d10;10 days;;", "Last 10 days", "d10"},
				{"m;1 month;;", "Last month", "m"},
				{"q;3 months;;", "Last quarter", "q"},
				{"y;1 year;;", "Last year", "y"},
				{"y10;10 years;;", "Last decade", "y10"},
				{"anno_0_1;;2016-01-01 00:00:00;2016-02-01 00:00:00", "v1.0 - v2.0", "anno_0_1"},
				{"anno_1_2;;2016-02-01 00:00:00;2016-03-01 00:00:00", "v2.0 - v3.0", "anno_1_2"},
				{"anno_2_3;;2016-03-01 00:00:00;2016-04-01 00:00:00", "v3.0 - v4.0", "anno_2_3"},
				{"anno_3_4;;2016-04-01 00:00:00;2016-05-01 00:00:00", "v4.0 - v5.0", "anno_3_4"},
				{"anno_4_5;;2016-05-01 00:00:00;2016-06-01 00:00:00", "v5.0 - v6.0", "anno_4_5"},
				{"v6.0 - now", "anno_5_now"},
			},
		},
	}
	// Execute test cases
	for index, test := range testCases {
		// Execute annotations & quick ranges call
		lib.ProcessAnnotations(&ctx, &test.annotations, test.dt)

		// Check annotations created
		gotAnnotations := getIDBResult(lib.QueryIDB(con, &ctx, "select * from annotations"))
		if !testlib.CompareSlices2D(test.expectedAnnotations, gotAnnotations) {
			t.Errorf(
				"test number %d, expected annotations:\n%+v\n%+v\ngot.",
				index+1, test.expectedAnnotations, gotAnnotations,
			)
		}
		// Clean up for next test
		lib.QueryIDB(con, &ctx, "drop series from annotations")

		// Check Quick Ranges created
		// Results contains some time values depending on current time ..Filtered func handles this
		gotQuickRanges := getIDBResultFiltered(lib.QueryIDB(con, &ctx, "select * from quick_ranges"))
		if !testlib.CompareSlices2D(test.expectedQuickRanges, gotQuickRanges) {
			t.Errorf(
				"test number %d, expected quick ranges:\n%+v\n%+v\ngot.",
				index+1, test.expectedQuickRanges, gotQuickRanges,
			)
		}
		// Clean up for next test
		lib.QueryIDB(con, &ctx, "drop series from quick_ranges")
	}
}
