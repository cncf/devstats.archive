package main

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"time"

	lib "devstats"
)

// valueDescription - return string description for given float value
// descFunc specifies how to treat value
// currently supported:
// `time_diff_as_string`: return string description of value that holds number of hours passed
// like 30 -> 1 day 6 hours, 100 -> 4 days 4 hours, etc...
func valueDescription(descFunc string, value float64) (result string) {
	switch descFunc {
	case "time_diff_as_string":
		return lib.DescriblePeriodInHours(value)
	default:
		lib.Printf("Error\nUnknown value description function '%v'\n", descFunc)
		fmt.Fprintf(os.Stdout, "Error\nUnknown value description function '%v'\n", descFunc)
		os.Exit(1)
	}
	return
}

// Returns multi row and multi column series names array (different for different rows)
// Each row must be in format: 'prefix;rowName;series1,series2,..,seriesN' serVal1 serVal2 ... serValN
// if multivalue is true then rowName is not used for generating series name
// Series name is independent from rowName, and metric returns "series_name;rowName"
// Multivalue series can even have partialy multivalue row: "this_comes_to_multivalues`this_comes_to_series_name", separator is `
func multiRowMultiColumn(expr, period string, multivalue, escapeValueName bool) (result []string) {
	ary := strings.Split(expr, ";")
	pref := ary[0]
	if pref == "" {
		lib.Printf("multiRowMultiColumn: WARNING: prefix '%v' (ary=%+v,expr=%+v,mv=%+v) skipping\n", pref, ary, expr, multivalue)
		return
	}
	splitColumns := strings.Split(ary[2], ",")
	if multivalue {
		rowNameAry := strings.Split(ary[1], "`")
		rowName := rowNameAry[0]
		if escapeValueName {
			rowName = lib.NormalizeName(rowName)
		}
		if len(rowNameAry) > 1 {
			rowNameNonMulti := lib.NormalizeName(rowNameAry[1])
			for _, series := range splitColumns {
				result = append(result, fmt.Sprintf("%s_%s_%s_%s;%s", pref, rowNameNonMulti, series, period, rowName))
			}
			return
		}
		for _, series := range splitColumns {
			result = append(result, fmt.Sprintf("%s_%s_%s;%s", pref, series, period, rowName))
		}
		return
	}
	rowName := lib.NormalizeName(ary[1])
	if rowName == "" {
		lib.Printf("multiRowMultiColumn: WARNING: rowName '%v' (%+v) maps to empty string, skipping\n", ary[1], ary)
		return
	}
	for _, series := range splitColumns {
		result = append(result, fmt.Sprintf("%s_%s_%s_%s", pref, rowName, series, period))
	}
	return
}

// Return default series names from multi column single row result
// It takes name "a,b,c,d,...,z" and period for example "q"
// and returns array [a_q, b_q, c_q, .., z_q]
func singleRowMultiColumn(columns, period string) (result []string) {
	splitColumns := strings.Split(columns, ",")
	for _, column := range splitColumns {
		result = append(result, column+"_"+period)
	}
	return
}

// Return default series names from multi row result single column
// Each row is "prefix,rowName", value (prefix is hardcoded in metric, so it is assumed safe)
// and returns array [a_q, b_q, c_q, .., z_q]
// if multivalue is true then rowName is not used for generating series name
// Series name is independent from rowName, and metric returns "series_name;rowName"
// Multivalue series can even have partialy multivalue row: "this_comes_to_multivalues`this_comes_to_series_name", separator is `
func multiRowSingleColumn(col, period string, multivalue, escapeValueName bool) (result []string) {
	ary := strings.Split(col, ",")
	pref := ary[0]
	if pref == "" {
		lib.Printf("multiRowSingleColumn: WARNING: prefix '%v' (ary=%+v,col=%+v,mv=%+v) skipping\n", pref, ary, col, multivalue)
		return
	}
	if multivalue {
		rowNameAry := strings.Split(ary[1], "`")
		rowName := rowNameAry[0]
		if escapeValueName {
			rowName = lib.NormalizeName(rowName)
		}
		if len(rowNameAry) > 1 {
			rowNameNonMulti := lib.NormalizeName(rowNameAry[1])
			return []string{fmt.Sprintf("%s_%s_%s;%s", pref, rowNameNonMulti, period, rowName)}
		}
		return []string{fmt.Sprintf("%s_%s;%s", pref, period, rowName)}
	}
	rowName := lib.NormalizeName(ary[1])
	if rowName == "" {
		lib.Printf("multiRowSingleColumn: WARNING: rowName '%v' (%+v) maps to empty string, skipping\n", ary[1], ary)
		return
	}
	return []string{fmt.Sprintf("%s_%s_%s", pref, rowName, period)}
}

// Generate name for given series row and period
func nameForMetricsRow(metric, name, period string, multivalue, escapeValueName bool) []string {
	switch metric {
	case "single_row_multi_column":
		return singleRowMultiColumn(name, period)
	case "multi_row_single_column":
		return multiRowSingleColumn(name, period, multivalue, escapeValueName)
	case "multi_row_multi_column":
		return multiRowMultiColumn(name, period, multivalue, escapeValueName)
	default:
		lib.Printf("Error\nUnknown metric '%v'\n", metric)
		fmt.Fprintf(os.Stdout, "Error\nUnknown metric '%v'\n", metric)
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

func workerThread(ch chan bool, ctx *lib.Ctx, seriesNameOrFunc, sqlQuery, period, desc string, multivalue, escapeValueName bool, nIntervals int, dt, from, to time.Time) {
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
	sqlQuery = strings.Replace(sqlQuery, "{{n}}", strconv.Itoa(nIntervals)+".0", -1)

	// Execute SQL query
	rows := lib.QuerySQLWithErr(sqlc, ctx, sqlQuery)
	defer rows.Close()

	// Get Number of columns
	// We support either query returnign single row with single numeric value
	// Or multiple rows, each containing string (series name) and its numeric value(s)
	columns, err := rows.Columns()
	lib.FatalOnError(err)
	nColumns := len(columns)

	// Use value descriptions?
	useDesc := desc != ""

	// Metric Results, assume they're floats
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
			lib.Printf(
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
		// In this simplest case 1 row, 1 column - series name is taken directly from YAML (metrics.yaml)
		// It usually uses `add_period_to_name: true` to have _period suffix, period{=h,d,w,m,q,y}
		name = seriesNameOrFunc
		if ctx.Debug > 0 {
			lib.Printf("%v - %v -> %v, %v\n", from, to, name, value)
		}
		// Add batch point
		fields := map[string]interface{}{"value": value}
		if useDesc {
			fields["descr"] = valueDescription(desc, value)
		}
		pt := lib.IDBNewPointWithErr(name, nil, fields, dt)
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
		allFields := make(map[string]map[string]interface{})
		for rows.Next() {
			// Get row values
			lib.FatalOnError(rows.Scan(pValues...))
			// Get first column name, and using it all series names
			// First column should contain nColumns - 1 names separated by ","
			name := string(*pValues[0].(*sql.RawBytes))
			names := nameForMetricsRow(seriesNameOrFunc, name, period, multivalue, escapeValueName)
			if len(names) > 0 {
				// Iterate values
				pFloats := pValues[1:]
				for idx, pVal := range pFloats {
					if pVal != nil {
						value, _ = strconv.ParseFloat(string(*pVal.(*sql.RawBytes)), 64)
					} else {
						value = 0.0
					}
					if multivalue {
						nameArr := strings.Split(names[idx], ";")
						seriesName := nameArr[0]
						seriesValueName := nameArr[1]
						if ctx.Debug > 0 {
							lib.Printf("%v - %v -> %v: %v[%v], %v\n", from, to, idx, seriesName, seriesValueName, value)
						}
						if _, ok := allFields[seriesName]; !ok {
							allFields[seriesName] = make(map[string]interface{})
						}
						allFields[seriesName][seriesValueName] = value
					} else {
						name = names[idx]
						if ctx.Debug > 0 {
							lib.Printf("%v - %v -> %v: %v, %v\n", from, to, idx, name, value)
						}
						// Add batch point
						fields := map[string]interface{}{"value": value}
						if useDesc {
							fields["descr"] = valueDescription(desc, value)
						}
						pt := lib.IDBNewPointWithErr(name, nil, fields, dt)
						bp.AddPoint(pt)
					}
				}
			}
		}
		// Multivalue series if any
		for seriesName, seriesValues := range allFields {
			pt := lib.IDBNewPointWithErr(seriesName, nil, seriesValues, dt)
			bp.AddPoint(pt)
		}
		lib.FatalOnError(rows.Err())
	}
	// Write the batch
	if !ctx.SkipIDB {
		err = ic.Write(bp)
		lib.FatalOnError(err)
	} else if ctx.Debug > 0 {
		lib.Printf("Skipping series write\n")
	}

	// Synchronize go routine
	if ch != nil {
		ch <- true
	}
}

func db2influxHistogram(ctx *lib.Ctx, seriesNameOrFunc, sqlQuery, interval, intervalAbbr string, nIntervals int) {
	// Connect to Postgres DB
	sqlc := lib.PgConn(ctx)
	defer sqlc.Close()

	// Connect to InfluxDB
	ic := lib.IDBConn(ctx)
	defer ic.Close()

	// Get BatchPoints
	bp := lib.IDBBatchPoints(ctx, &ic)

	// Prepare SQL query
	dbInterval := fmt.Sprintf("%d %s", nIntervals, interval)
	if interval == lib.Quarter {
		dbInterval = fmt.Sprintf("%d month", nIntervals*3)
	}
	sqlQuery = strings.Replace(sqlQuery, "{{period}}", dbInterval, -1)
	sqlQuery = strings.Replace(sqlQuery, "{{n}}", strconv.Itoa(nIntervals)+".0", -1)

	// Execute SQL query
	rows := lib.QuerySQLWithErr(sqlc, ctx, sqlQuery)
	defer rows.Close()

	// Get number of columns, for histograms there should be exactly 2 columns
	columns, err := rows.Columns()
	lib.FatalOnError(err)
	nColumns := len(columns)

	// Expect 2 columns: string column with name and float column with value
	var (
		value float64
		name  string
	)
	if nColumns == 2 {
		// Drop existing data
		lib.SafeQueryIDB(ic, ctx, "drop measurement "+seriesNameOrFunc)

		// Add new data
		tm := time.Now()
		rowCount := 0
		for rows.Next() {
			lib.FatalOnError(rows.Scan(&name, &value))
			if ctx.Debug > 0 {
				lib.Printf("hist %v, %v %v -> %v, %v\n", seriesNameOrFunc, nIntervals, interval, name, value)
			}
			// Add batch point
			fields := map[string]interface{}{"name": name, "value": value}
			pt := lib.IDBNewPointWithErr(seriesNameOrFunc, nil, fields, tm)
			bp.AddPoint(pt)
			rowCount++
			tm = tm.Add(-time.Hour)
		}
		if ctx.Debug > 0 {
			lib.Printf("hist %v, %v %v: %v rows\n", seriesNameOrFunc, nIntervals, interval, rowCount)
		}
		lib.FatalOnError(rows.Err())
	} else if nColumns >= 3 {
		var (
			fValue float64
			sValue string
		)
		columns, err := rows.Columns()
		lib.FatalOnError(err)
		nColumns := len(columns)
		pValues := make([]interface{}, nColumns)
		for i := range columns {
			pValues[i] = new(sql.RawBytes)
		}
		seriesToClear := make(map[string]time.Time)
		for rows.Next() {
			// Get row values
			lib.FatalOnError(rows.Scan(pValues...))
			name := string(*pValues[0].(*sql.RawBytes))
			names := nameForMetricsRow(seriesNameOrFunc, name, intervalAbbr, false, false)
			nNames := len(names)
			if nNames > 0 {
				for i := 0; i < nNames; i++ {
					pName := pValues[2*i+1]
					if pName != nil {
						sValue = string(*pName.(*sql.RawBytes))
					} else {
						sValue = "(nil)"
					}
					pVal := pValues[2*i+2]
					if pVal != nil {
						fValue, _ = strconv.ParseFloat(string(*pVal.(*sql.RawBytes)), 64)
					} else {
						fValue = 0.0
					}
					name = names[i]
					if ctx.Debug > 0 {
						lib.Printf("hist %v, %v %v -> %v, %v\n", name, nIntervals, interval, sValue, fValue)
					}
					tm, ok := seriesToClear[name]
					if ok {
						tm = tm.Add(-time.Hour)
						seriesToClear[name] = tm
					} else {
						tm = time.Now()
						seriesToClear[name] = tm
					}
					// Add batch point
					fields := map[string]interface{}{"name": sValue, "value": fValue}
					pt := lib.IDBNewPointWithErr(name, nil, fields, tm)
					bp.AddPoint(pt)
				}
			}
		}
		lib.FatalOnError(rows.Err())
		if len(seriesToClear) > 0 {
			allSeries := ""
			for series := range seriesToClear {
				allSeries += series + "|"
			}
			allSeries = allSeries[0 : len(allSeries)-1]
			lib.SafeQueryIDB(ic, ctx, "drop series from /"+allSeries+"/")
		}
	}
	// Write the batch
	if !ctx.SkipIDB {
		err = ic.Write(bp)
		lib.FatalOnError(err)
	} else if ctx.Debug > 0 {
		lib.Printf("Skipping series write\n")
	}
}

func db2influx(seriesNameOrFunc, sqlFile, from, to, intervalAbbr string, hist, multivalue, escapeValueName bool, desc string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Read SQL file.
	bytes, err := ioutil.ReadFile(sqlFile)
	lib.FatalOnError(err)
	sqlQuery := string(bytes)

	// Process interval
	interval, nIntervals, intervalStart, nextIntervalStart, prevIntervalStart := lib.GetIntervalFunctions(intervalAbbr)

	if hist {
		db2influxHistogram(&ctx, seriesNameOrFunc, sqlQuery, interval, intervalAbbr, nIntervals)
		return
	}

	// Parse input dates
	dFrom := lib.TimeParseAny(from)
	dTo := lib.TimeParseAny(to)

	// Round dates to the given interval
	dFrom = intervalStart(dFrom)
	dTo = nextIntervalStart(dTo)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)

	// Run
	lib.Printf("db2influx.go: Running (on %d CPUs): %v - %v with interval %s, descriptions '%s', multivalue: %v, escape_value_name: %v\n", thrN, dFrom, dTo, interval, desc, multivalue, escapeValueName)
	dt := dFrom
	var pDt time.Time
	if thrN > 1 {
		chanPool := []chan bool{}
		for dt.Before(dTo) {
			ch := make(chan bool)
			chanPool = append(chanPool, ch)
			nDt := nextIntervalStart(dt)
			if nIntervals <= 1 {
				pDt = dt
			} else {
				pDt = lib.AddNIntervals(dt, 1-nIntervals, nextIntervalStart, prevIntervalStart)
			}
			go workerThread(ch, &ctx, seriesNameOrFunc, sqlQuery, intervalAbbr, desc, multivalue, escapeValueName, nIntervals, dt, pDt, nDt)
			dt = nDt
			if len(chanPool) == thrN {
				ch = chanPool[0]
				<-ch
				chanPool = chanPool[1:]
			}
		}
		lib.Printf("Final threads join\n")
		for _, ch := range chanPool {
			<-ch
		}
	} else {
		lib.Printf("Using single threaded version\n")
		for dt.Before(dTo) {
			nDt := nextIntervalStart(dt)
			if nIntervals <= 1 {
				pDt = dt
			} else {
				pDt = lib.AddNIntervals(dt, 1-nIntervals, nextIntervalStart, prevIntervalStart)
			}
			workerThread(nil, &ctx, seriesNameOrFunc, sqlQuery, intervalAbbr, desc, multivalue, escapeValueName, nIntervals, dt, pDt, nDt)
			dt = nDt
		}
	}
	// Finished
	lib.Printf("All done.\n")
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 6 {
		lib.Printf(
			"Required series name, SQL file name, from, to, period " +
				"[series_name_or_func some.sql '2015-08-03' '2017-08-21' h|d|w|m|q|y [hist,desc:time_diff_as_string]]\n",
		)
		lib.Printf(
			"Series name (series_name_or_func) will become exact series name if " +
				"query return just single numeric value\n",
		)
		lib.Printf("For queries returning multiple rows 'series_name_or_func' will be used as function that\n")
		lib.Printf("receives data row and period and returns name and value(s) for it\n")
		os.Exit(1)
	}
	hist := false
	multivalue := false
	escapeValueName := false
	desc := ""
	if len(os.Args) > 6 {
		opts := strings.Split(os.Args[6], ",")
		optMap := make(map[string]string)
		for _, opt := range opts {
			optArr := strings.Split(opt, ":")
			optName := optArr[0]
			optVal := ""
			if len(optArr) > 1 {
				optVal = optArr[1]
			}
			optMap[optName] = optVal
		}
		if _, ok := optMap["hist"]; ok {
			hist = true
		}
		if _, ok := optMap["multivalue"]; ok {
			multivalue = true
		}
		if _, ok := optMap["escape_value_name"]; ok {
			escapeValueName = true
		}
		if d, ok := optMap["desc"]; ok {
			desc = d
		}
	}
	db2influx(os.Args[1], os.Args[2], os.Args[3], os.Args[4], os.Args[5], hist, multivalue, escapeValueName, desc)
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
