package main

import (
	"os"
	"strings"
	"time"

	lib "devstats"
)

// getMatchingSeries returns series name that matches given regexp
func getMatchingSeries(ctx *lib.Ctx, seriesRegExp string) (seriesSet map[string]struct{}) {
	// Connect to InfluxDB
	ic := lib.IDBConn(ctx)
	defer func() { lib.FatalOnError(ic.Close()) }()

	// Create result map
	seriesSet = make(map[string]struct{})

	// Get series that match given regexp by selecting their last value
	lib.Printf("Fetching series names matching %s\n", seriesRegExp)
	res := lib.QueryIDB(ic, ctx, "select last(*) from "+seriesRegExp)
	allSeries := res[0].Series
	for _, series := range allSeries {
		seriesSet[series.Name] = struct{}{}
	}
	lib.Printf("Found %d series matching %s: %v\n", len(allSeries), seriesRegExp, seriesSet)
	return
}

func workerThread(ch chan bool, ctx *lib.Ctx, seriesSet map[string]struct{}, period string, desc bool, values []string, from, to time.Time) {
	// Connect to InfluxDB
	ic := lib.IDBConn(ctx)
	defer func() { lib.FatalOnError(ic.Close()) }()

	// Get BatchPoints
	var pts lib.IDBBatchPointsN
	bp := lib.IDBBatchPoints(ctx, &ic)
	pts.NPoints = 0
	pts.Points = &bp

	// Zero
	fields := make(map[string]interface{})
	for _, value := range values {
		if value == "*" {
			continue
		}
		fields[value] = 0.0
	}
	if desc {
		fields["descr"] = ""
	}

	// YYYY-MM-DDTHH:MI:SSZ
	idbFrom := lib.ToIDBDate(from)

	for series := range seriesSet {
		if ctx.Debug > 0 {
			lib.Printf("%+v %v - %v %v\n", series, from, to, period)
		}

		// Support overwite all
		if values[0] == "*" {
			res := lib.QueryIDB(ic, ctx, "select * from \""+series+"\" where time = '"+idbFrom+"'")
			allSeries := res[0].Series
			if len(allSeries) == 0 {
				continue
			}
			series := allSeries[0]
			columns := series.Columns
			if ctx.Debug > 0 {
				lib.Printf("%v %s: * -> %v\n", series, idbFrom, columns)
			}
			n := 0
			for _, column := range columns {
				if column == lib.TimeCol {
					continue
				}
				fields[column] = 0.0
				n++
			}
			if n == 0 {
				continue
			}
		}

		// Add batch point
		pt := lib.IDBNewPointWithErr(ctx, series, nil, fields, from)
		lib.IDBAddPointN(ctx, &ic, &pts, pt)
	}

	// Write the batch
	if !ctx.SkipIDB {
		lib.FatalOnError(lib.IDBWritePointsN(ctx, &ic, &pts))
	} else if ctx.Debug > 0 {
		lib.Printf("Skipping series write\n")
	}

	// Synchronize go routine
	if ch != nil {
		ch <- true
	}
}

func z2influx(series, from, to, intervalAbbr string, desc bool, values []string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Strip function to be used by MapString
	stripFunc := func(x string) string { return strings.TrimSpace(x) }

	// Stripping whitespace from series names
	var seriesSet map[string]struct{}
	if len(series) > 0 && series[0] == '/' {
		seriesSet = getMatchingSeries(&ctx, series)
	} else {
		seriesSet = lib.StringsMapToSet(
			stripFunc,
			strings.Split(series, ","),
		)
	}

	// Parse input dates
	dFrom := lib.TimeParseAny(from)
	dTo := lib.TimeParseAny(to)

	// Process interval
	interval, _, intervalStart, nextIntervalStart, _ := lib.GetIntervalFunctions(intervalAbbr, false)

	// Round dates to the given interval
	dFrom = intervalStart(dFrom)
	dTo = nextIntervalStart(dTo)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)

	// Run
	nValues := len(values)
	if nValues <= 100 {
		lib.Printf("z2influx.go: Running (on %d CPUs): %v - %v with interval %s, descriptions %v, values: %v\n", thrN, dFrom, dTo, interval, desc, values)
	} else {
		lib.Printf("z2influx.go: Running (on %d CPUs): %v - %v with interval %s, descriptions %v, nValues: %d\n", thrN, dFrom, dTo, interval, desc, nValues)
	}
	dt := dFrom
	if thrN > 1 {
		ch := make(chan bool)
		nThreads := 0
		for dt.Before(dTo) {
			nDt := nextIntervalStart(dt)
			go workerThread(ch, &ctx, seriesSet, intervalAbbr, desc, values, dt, nDt)
			dt = nDt
			nThreads++
			if nThreads == thrN {
				<-ch
				nThreads--
			}
		}
		lib.Printf("Final threads join\n")
		for nThreads > 0 {
			<-ch
			nThreads--
		}
	} else {
		lib.Printf("Using single threaded version\n")
		for dt.Before(dTo) {
			nDt := nextIntervalStart(dt)
			workerThread(nil, &ctx, seriesSet, intervalAbbr, desc, values, dt, nDt)
			dt = nDt
		}
	}
	// Finished
	lib.Printf("All done.\n")
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 5 {
		lib.Printf("%s: Required args: 'series1,series2,..' from to period\n"+
			"Example: 's1,s2,s3' 2015-08-03 2017-08-04' h|d|w|m|q|y [desc,values:value1;value2;...;valueN]\n"+
			"Example: '/^open_(issues|prs)_sigs_milestones/' 2015-08-03 2017-08-04' h|d|w|m|q|y 'values:*'\n",
			os.Args[0],
		)
		os.Exit(1)
	}
	desc := false
	values := []string{}
	if len(os.Args) > 5 {
		opts := strings.Split(os.Args[5], ",")
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
		if _, ok := optMap["desc"]; ok {
			desc = true
		}
		if d, ok := optMap["values"]; ok {
			sValues := d
			values = strings.Split(sValues, ";")
		}
	}
	if len(values) == 0 {
		values = []string{"value"}
	}
	z2influx(os.Args[1], os.Args[2], os.Args[3], os.Args[4], desc, values)
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
