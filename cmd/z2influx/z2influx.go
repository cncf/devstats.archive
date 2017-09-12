package main

import (
	"fmt"
	"os"
	"strings"
	"time"

	lib "k8s.io/test-infra/gha2db"
)

func workerThread(ch chan bool, ctx *lib.Ctx, seriesSet map[string]struct{}, period string, from, to time.Time) {
	fmt.Printf("%+v %v - %v %v\n", seriesSet, from, to, period)
	// Synchronize go routine
	if ch != nil {
		ch <- true
	}
}

func z2influx(series, from, to, intervalAbbr string) {
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
	interval, intervalStart, nextIntervalStart := lib.GetIntervalFunctions(intervalAbbr)

	// Round dates to the given interval
	dFrom = intervalStart(dFrom)
	dTo = nextIntervalStart(dTo)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)

	// Run
	fmt.Printf("z2influx.go: Running (on %d CPUs): %v - %v with interval %s\n", thrN, dFrom, dTo, interval)
	dt := dFrom
	if thrN > 1 {
		chanPool := []chan bool{}
		for dt.Before(dTo) {
			ch := make(chan bool)
			chanPool = append(chanPool, ch)
			nDt := nextIntervalStart(dt)
			go workerThread(ch, &ctx, seriesSet, intervalAbbr, dt, nDt)
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
			workerThread(nil, &ctx, seriesSet, intervalAbbr, dt, nDt)
			dt = nDt
		}
	}
	// Finished
	fmt.Printf("All done.\n")
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 5 {
		fmt.Print("Required args: 'series1,series2,..' from to period\n",
			"'s1,s2,s3' 2015-08-03 2017-08-2' h|d|w|m|q|y\n",
		)
		os.Exit(1)
	}
	z2influx(os.Args[1], os.Args[2], os.Args[3], os.Args[4])
	dtEnd := time.Now()
	fmt.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
