package main

import (
	"os"
	"strings"
	"time"

	lib "devstats"
)

func workerThread(ch chan bool, ctx *lib.Ctx, seriesSet map[string]struct{}, period string, desc bool, values []string, from, to time.Time) {
	// Connect to InfluxDB
	ic := lib.IDBConn(ctx)
	defer ic.Close()

	// Get BatchPoints
	bp := lib.IDBBatchPoints(ctx, &ic)

	// Zero
	fields := make(map[string]interface{})
	for _, value := range values {
		fields[value] = 0.0
	}
	if desc {
		fields["descr"] = ""
	}

	for series := range seriesSet {
		if ctx.Debug > 0 {
			lib.Printf("%+v %v - %v %v\n", series, from, to, period)
		}

		// Add batch point
		pt := lib.IDBNewPointWithErr(series, nil, fields, from)
		bp.AddPoint(pt)
	}

	// Write the batch
	if !ctx.SkipIDB {
		err := ic.Write(bp)
		lib.FatalOnError(err)
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
	seriesSet = lib.StringsMapToSet(
		stripFunc,
		strings.Split(series, ","),
	)

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
	lib.Printf("z2influx.go: Running (on %d CPUs): %v - %v with interval %s, descriptions %v, values: %v\n", thrN, dFrom, dTo, interval, desc, values)
	dt := dFrom
	if thrN > 1 {
		chanPool := []chan bool{}
		for dt.Before(dTo) {
			ch := make(chan bool)
			chanPool = append(chanPool, ch)
			nDt := nextIntervalStart(dt)
			go workerThread(ch, &ctx, seriesSet, intervalAbbr, desc, values, dt, nDt)
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
			"Example: 's1,s2,s3' 2015-08-03 2017-08-2' h|d|w|m|q|y [desc,values:value1;value2;...;valueN]\n",
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
