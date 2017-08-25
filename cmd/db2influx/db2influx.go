package main

import (
	"fmt"
	"io/ioutil"
	lib "k8s.io/test-infra/gha2db"
	"os"
	"strings"
	"time"
)

// Generate name for given series row and period
func nameForMetricsRow(metric, name, period string) string {
	if metric == "sig_mentions_data" {
		return fmt.Sprintf("%s_%s", strings.Replace(name, "-", "_", -1), period)
	} else if metric == "prs_merged_data" {
		r := strings.NewReplacer("-", "_", "/", "_", ".", "_")
		return fmt.Sprintf("prs_%s_%s", r.Replace(name), period)
	} else {
		fmt.Printf("Error\nUnknown metric '%v'\n", metric)
		os.Exit(1)
	}
	return ""
}

// Round float64 to int
func roundF2I(val float64) int {
	if val < 0.0 {
		return int(val - 0.5)
	}
	return int(val + 0.5)
}

func workerThread(ch chan bool, ctx *lib.Ctx, seriesNameOrFunc, sqlQuery, period string, from, to time.Time) {
	// Connect to Postgres DB
	sqlc := lib.PgConn(ctx)
	defer sqlc.Close()

	// Connect to InfluxDB
	ic, bp := lib.IDBConn(ctx)
	defer ic.Close()

	// Prepare SQL query
	sFrom := lib.ToSQLDate(from)
	sTo := lib.ToSQLDate(to)
	sqlQuery = strings.Replace(sqlQuery, "{{from}}", sFrom, -1)
	sqlQuery = strings.Replace(sqlQuery, "{{to}}", sTo, -1)

	// Execute SQL query
	rows := lib.QuerySQLWithErr(sqlc, ctx, sqlQuery)
	defer rows.Close()

	// Get Number of columns
	// We support either query returnign single row with single numeric value
	// Or multiple rows, each containing string (series name) and its numeric value
	columns, err := rows.Columns()
	lib.FatalOnError(err)
	nColumns := len(columns)

	// Metric Results, currently assume they're integers
	var pValue *float64
	value := 0
	name := ""
	// Single row & single column result
	if nColumns == 1 {
		rowCount := 0
		for rows.Next() {
			lib.FatalOnError(rows.Scan(&pValue))
			rowCount++
		}
		lib.FatalOnError(rows.Err())
		if rowCount != 1 {
			fmt.Printf(
				"Error:\nQuery should return either single value or "+
					"multiple rows, each containing string and number\n"+
					"Got %d rows, each containing single number\nQuery:\n",
				rowCount, sqlQuery,
			)
		}
		// Handle nulls
		if pValue != nil {
			value = roundF2I(*pValue)
		}
		name = seriesNameOrFunc
		if ctx.Debug > 0 {
			fmt.Printf("%v - %v -> %v, %v\n", from, to, name, value)
		}
		// Add batch point
		fields := map[string]interface{}{"value": value}
		pt := lib.IDBNewPointWithErr(name, nil, fields, from)
		bp.AddPoint(pt)
	} else if nColumns == 2 {
		// Multiple rows, each with (series name, value)
		for rows.Next() {
			lib.FatalOnError(rows.Scan(&name, &pValue))
			if pValue != nil {
				value = roundF2I(*pValue)
			}
			name = nameForMetricsRow(seriesNameOrFunc, name, period)
			if ctx.Debug > 0 {
				fmt.Printf("%v - %v -> %v, %v\n", from, to, name, value)
			}
			// Add batch point
			fields := map[string]interface{}{"value": value}
			pt := lib.IDBNewPointWithErr(name, nil, fields, from)
			bp.AddPoint(pt)
		}
		lib.FatalOnError(rows.Err())
	} else {
		fmt.Printf(
			"Wrong query:\n#{q}\nMetrics query should either return single row " +
				"with single value or at least 1 row, each with two values\n",
		)
		os.Exit(1)
	}
	// Write the batch
	err = ic.Write(bp)
	lib.FatalOnError(err)

	// Synchronize go routine
	if ch != nil {
		ch <- true
	}
}

func db2influx(seriesNameOrFunc, sqlFile, from, to, intervalAbbr string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Parse input dates
	dFrom := lib.TimeParseAny(from)
	dTo := lib.TimeParseAny(to)

	// Read SQL file.
	bytes, err := ioutil.ReadFile(sqlFile)
	lib.FatalOnError(err)
	sqlQuery := string(bytes)

	// Process interval
	interval := ""
	var (
		intervalStart     func(time.Time) time.Time
		nextIntervalStart func(time.Time) time.Time
	)
	switch strings.ToLower(intervalAbbr) {
	case "h":
		interval = "hour"
		intervalStart = lib.HourStart
		nextIntervalStart = lib.NextHourStart
	case "d":
		interval = "day"
		intervalStart = lib.DayStart
		nextIntervalStart = lib.NextDayStart
	case "w":
		interval = "week"
		intervalStart = lib.WeekStart
		nextIntervalStart = lib.NextWeekStart
	case "m":
		interval = "month"
		intervalStart = lib.MonthStart
		nextIntervalStart = lib.NextMonthStart
	case "q":
		interval = "quarter"
		intervalStart = lib.QuarterStart
		nextIntervalStart = lib.NextQuarterStart
	case "y":
		interval = "year"
		intervalStart = lib.YearStart
		nextIntervalStart = lib.NextYearStart
	default:
		fmt.Printf("Error:\nUnknown interval '%v'\n", intervalAbbr)
		os.Exit(1)
	}

	// Round dates to the given interval
	dFrom = intervalStart(dFrom)
	dTo = nextIntervalStart(dTo)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)

	// Run
	fmt.Printf("Running (on %d CPUs): %v - %v with interval %s\n", thrN, dFrom, dTo, interval)
	dt := dFrom
	if thrN > 1 {
		chanPool := []chan bool{}
		for dt.Before(dTo) {
			ch := make(chan bool)
			chanPool = append(chanPool, ch)
			nDt := nextIntervalStart(dt)
			go workerThread(ch, &ctx, seriesNameOrFunc, sqlQuery, intervalAbbr, dt, nDt)
			dt = nDt
			if len(chanPool) == thrN {
				ch = chanPool[0]
				<-ch
				chanPool = chanPool[1:]
			}
		}
		fmt.Printf("Final threads join\n")
		for _, ch := range chanPool {
			<-ch
		}
	} else {
		fmt.Printf("Using single threaded version\n")
		for dt.Before(dTo) {
			nDt := nextIntervalStart(dt)
			workerThread(nil, &ctx, seriesNameOrFunc, sqlQuery, intervalAbbr, dt, nDt)
			dt = nDt
		}
	}
	// Finished
	fmt.Printf("All done.\n")
}

func main() {
	if len(os.Args) < 6 {
		fmt.Printf(
			"Required series name, SQL file name, from, to, period " +
				"[series_name_or_func some.sql '2015-08-03' '2017-08-21' d|w|m|y\n",
		)
		fmt.Printf(
			"Series name (series_name_or_func) will become exact series name if " +
				"query return just single numeric value\n",
		)
		fmt.Printf("For queries returning multiple rows 'series_name_or_func' will be used as function that\n")
		fmt.Printf("receives data row and period and returns name and value for it\n")
		os.Exit(1)
	}
	db2influx(os.Args[1], os.Args[2], os.Args[3], os.Args[4], os.Args[5])
}
