package main

import (
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"time"

	lib "devstats"
)

func idbTest(db string, nSeries, nVals, nTags, nDts int) {
	var ctx lib.Ctx
	ctx.Init()
	lib.Printf("Running on %s database, %d series, %d values, %d tags, %d dates\n", db, nSeries, nVals, nTags, nDts)

	rSrc := rand.NewSource(time.Now().UnixNano())
	rnd := rand.New(rSrc)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)
	lib.Printf("idb_tst.go: Running (%v CPUs)\n", thrN)

	// Connect to InfluxDB
	ic := lib.IDBConn(&ctx)
	ctx.IDBDB = db

	// Drop & create requested database
	lib.QueryIDB(ic, &ctx, "drop database "+ctx.IDBDB)
	lib.QueryIDB(ic, &ctx, "create database "+ctx.IDBDB)

	// Process series using MT
	ch := make(chan bool)
	dtStart := time.Now()
	lastTime := dtStart
	nThreads := 0
	processed := 0
	for i := 0; i < nSeries; i++ {
		go func(c chan bool, idx int) {
			serName := fmt.Sprintf("series%d", idx)
			if ctx.Debug > 0 {
				lib.Printf("Processing %s series\n", serName)
			}

			// Get BatchPoints
			var pts lib.IDBBatchPointsN
			bp := lib.IDBBatchPoints(&ctx, &ic)
			pts.NPoints = 0
			pts.Points = &bp

			nDtsR := 1 + rnd.Intn(nDts)

			tm := lib.HourStart(time.Now())
			for d := 0; d < nDtsR; d++ {
				nValsR := 1 + rnd.Intn(nDts)
				nTagsR := 1 + rnd.Intn(nDts)
				tags := make(map[string]string)
				fields := make(map[string]interface{})
				for v := 0; v < nValsR; v++ {
					valName := fmt.Sprintf("valueName%d", v)
					valValue := float64((v + 1) * (d + 1) * (idx + 1))
					fields[valName] = valValue
				}
				for t := 0; t < nTagsR; t++ {
					tagName := fmt.Sprintf("tagName%d", t)
					tagValue := fmt.Sprintf("tagValue%d_%d_%d", t, d, idx)
					tags[tagName] = tagValue
				}
				pt := lib.IDBNewPointWithErr(&ctx, serName, tags, fields, tm)
				lib.IDBAddPointN(&ctx, &ic, &pts, pt)
				tm = tm.Add(-time.Hour)
			}
			// Write points
			lib.FatalOnError(lib.IDBWritePointsN(&ctx, &ic, &pts))

			// Sync
			c <- true
		}(ch, i)

		nThreads++
		if nThreads == thrN {
			<-ch
			nThreads--
			processed++
			lib.ProgressInfo(processed, nSeries, dtStart, &lastTime, time.Duration(1)*time.Second, "")
		}
	}
	lib.Printf("Final threads join\n")
	for nThreads > 0 {
		<-ch
		nThreads--
		processed++
		lib.ProgressInfo(processed, nSeries, dtStart, &lastTime, time.Duration(1)*time.Second, "")
	}
}

// main args: dbname n-series n-values n-tags n-datetimes
func main() {
	dtStart := time.Now()
	if len(os.Args) < 6 {
		lib.Printf("Required args: dbname n-series n-values n-tags n-datetimes\n")
		os.Exit(1)
	}
	nSeries, err := strconv.Atoi(os.Args[2])
	lib.FatalOnError(err)
	nVals, err := strconv.Atoi(os.Args[3])
	lib.FatalOnError(err)
	nTags, err := strconv.Atoi(os.Args[4])
	lib.FatalOnError(err)
	nDts, err := strconv.Atoi(os.Args[5])
	lib.FatalOnError(err)
	idbTest(os.Args[1], nSeries, nVals, nTags, nDts)
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
