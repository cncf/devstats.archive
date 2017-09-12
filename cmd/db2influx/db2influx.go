package main

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"time"

	lib "k8s.io/test-infra/gha2db"
)

// Generate name for given series row and period
func nameForMetricsRow(metric, name, period string) []string {
	switch metric {
	case "sig_mentions_data":
		return []string{fmt.Sprintf("%s_%s", strings.Replace(name, "-", "_", -1), period)}
	case "sig_mentions_breakdown_data":
		return []string{fmt.Sprintf("bd_%s_%s", strings.Replace(name, "-", "_", -1), period)}
	case "prs_merged_data":
		r := strings.NewReplacer("-", "_", "/", "_", ".", "_")
		return []string{fmt.Sprintf("prs_%s_%s", r.Replace(name), period)}
	case "default_multi_column":
		splitted := strings.Split(name, ",")
		var result []string
		for _, str := range splitted {
			result = append(result, str+"_"+period)
		}
		return result
	default:
		fmt.Printf("Error\nUnknown metric '%v'\n", metric)
		os.Exit(1)
	}
	return []string{""}
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
	ic := lib.IDBConn(ctx)
	defer ic.Close()

	// Get BatchPoints
	bp := lib.IDBBatchPoints(ctx, &ic)

	// Prepare SQL query
	sFrom := lib.ToYMDHMSDate(from)
	sTo := lib.ToYMDHMSDate(to)
	sqlQuery = strings.Replace(sqlQuery, "{{from}}", sFrom, -1)
	sqlQuery = strings.Replace(sqlQuery, "{{to}}", sTo, -1)

	// Execute SQL query
	rows := lib.QuerySQLWithErr(sqlc, ctx, sqlQuery)
	defer rows.Close()

	// Get Number of columns
	// We support either query returnign single row with single numeric value
	// Or multiple rows, each containing string (series name) and its numeric value(s)
	columns, err := rows.Columns()
	lib.FatalOnError(err)
	nColumns := len(columns)

	// Metric Results, currently assume they're integers
	var (
		pValue *float64
		value  float64
		name   string
	)
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
					"multiple rows, each containing string and numbers\n"+
					"Got %d rows, each containing single number\nQuery:%s\n",
				rowCount, sqlQuery,
			)
		}
		// Handle nulls
		if pValue != nil {
			value = *pValue
		}
		name = seriesNameOrFunc
		if ctx.Debug > 0 {
			fmt.Printf("%v - %v -> %v, %v\n", from, to, name, value)
		}
		// Add batch point
		fields := map[string]interface{}{"value": value}
		pt := lib.IDBNewPointWithErr(name, nil, fields, from)
		bp.AddPoint(pt)
	} else if nColumns >= 2 {
		// Multiple rows, each with (series name, value(s))
		// Number of columns
		columns, err := rows.Columns()
		lib.FatalOnError(err)
		nColumns := len(columns)
		// Alocate nColumns numeric values (first is series name)
		pValues := make([]interface{}, nColumns)
		for i := range columns {
			pValues[i] = new(sql.RawBytes)
		}
		for rows.Next() {
			// Get row values
			lib.FatalOnError(rows.Scan(pValues...))
			// Get first column name, and using it all series names
			// First column should contain nColumns - 1 names separated by ","
			name := string(*pValues[0].(*sql.RawBytes))
			names := nameForMetricsRow(seriesNameOrFunc, name, period)
			// Iterate values
			pFloats := pValues[1:]
			for idx, pVal := range pFloats {
				if pVal != nil {
					value, _ = strconv.ParseFloat(string(*pVal.(*sql.RawBytes)), 64)
				} else {
					value = 0.0
				}
				name = names[idx]
				if ctx.Debug > 0 {
					fmt.Printf("%v - %v -> %v: %v, %v\n", from, to, idx, name, value)
				}
				// Add batch point
				fields := map[string]interface{}{"value": value}
				pt := lib.IDBNewPointWithErr(name, nil, fields, from)
				bp.AddPoint(pt)
			}
		}
		lib.FatalOnError(rows.Err())
	}
	// Write the batch
	if !ctx.SkipIDB {
		err = ic.Write(bp)
		lib.FatalOnError(err)
	} else if ctx.Debug > 0 {
		fmt.Printf("Skipping series write\n")
	}

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
	interval, intervalStart, nextIntervalStart := lib.GetIntervalFunctions(intervalAbbr)

	// Round dates to the given interval
	dFrom = intervalStart(dFrom)
	dTo = nextIntervalStart(dTo)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)

	// Run
	fmt.Printf("db2influx.go: Running (on %d CPUs): %v - %v with interval %s\n", thrN, dFrom, dTo, interval)
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
	dtStart := time.Now()
	if len(os.Args) < 6 {
		fmt.Printf(
			"Required series name, SQL file name, from, to, period " +
				"[series_name_or_func some.sql '2015-08-03' '2017-08-21' h|d|w|m|q|y\n",
		)
		fmt.Printf(
			"Series name (series_name_or_func) will become exact series name if " +
				"query return just single numeric value\n",
		)
		fmt.Printf("For queries returning multiple rows 'series_name_or_func' will be used as function that\n")
		fmt.Printf("receives data row and period and returns name and value(s) for it\n")
		os.Exit(1)
	}
	db2influx(os.Args[1], os.Args[2], os.Args[3], os.Args[4], os.Args[5])
	dtEnd := time.Now()
	fmt.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
