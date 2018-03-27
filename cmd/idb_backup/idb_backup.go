package main

import (
	lib "devstats"
	"encoding/json"
	"fmt"
	"strings"
	"time"
)

func copySeries(ch chan bool, ctxI, ctxO *lib.Ctx, seriesName string) {
	// Connect to InfluxDB databases
	icI := lib.IDBConn(ctxI)
	icO := lib.IDBConn(ctxO)
	defer func() {
		lib.FatalOnError(icI.Close())
		lib.FatalOnError(icO.Close())
	}()

	// Get BatchPoints
	var pts lib.IDBBatchPointsN
	bp := lib.IDBBatchPoints(ctxO, &icO)
	pts.NPoints = 0
	pts.Points = &bp

	// Get values from series
	//lib.Printf("seriesName: '%s'\n", seriesName)
	res := lib.QueryIDB(icI, ctxI, "select * from \""+seriesName+"\" group by *")
	allSeries := res[0].Series
	for _, series := range allSeries {
		// Add batch point(s)
		dt := time.Now()
		columns := series.Columns
		values := series.Values
		tags := series.Tags
		for _, value := range values {
			fields := make(map[string]interface{})
			for i, column := range columns {
				if column == "time" {
					dt = lib.TimeParseIDB(value[i].(string))
				} else if value[i] != nil {
					switch interfaceValue := value[i].(type) {
					case json.Number:
						fVal, err := interfaceValue.Float64()
						lib.FatalOnError(err)
						fields[column] = fVal
					case string:
						fields[column] = interfaceValue
					default:
						lib.Fatalf("unknown type %T/%+v for field \"%s\"", interfaceValue, interfaceValue, column)
					}
				}
			}
			if ctxI.Debug > 0 || ctxO.Debug > 0 {
				fmt.Printf("%s: tags=%+v, fields=%+v, dt=%v\n", series.Name, tags, fields, dt)
			}
			pt := lib.IDBNewPointWithErr(ctxO, series.Name, tags, fields, dt)
			lib.IDBAddPointN(ctxO, &icO, &pts, pt)
		}
	}
	// Write the batch
	if !ctxO.SkipIDB {
		lib.FatalOnError(lib.IDBWritePointsN(ctxO, &icO, &pts))
	} else if ctxI.Debug > 0 || ctxO.Debug > 0 {
		lib.Printf("Skipping tags series write\n")
	}
	if ch != nil {
		ch <- true
	}
}

// Backup all series "from" --> "to"
func idbBackup() {
	// Environment context parse
	var (
		ctxI lib.Ctx
		ctxO lib.Ctx
	)

	// Replace all environment variables starting with "IDB_"
	// with contents of variables with "_SRC" added - if defined
	// So if there is "IDB_HOST_SRC" variable defined - it will replace "IDB_HOST" and so on
	env := lib.EnvReplace("IDB_", "_SRC")
	ctxI.Init()
	lib.EnvRestore(env)

	// Same for output config
	env = lib.EnvReplace("IDB_", "_DST")
	ctxO.Init()
	lib.EnvRestore(env)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctxI)
	lib.Printf("idb_backup.go: Running (%v CPUs)\n", thrN)

	// Connect to InfluxDB
	ic := lib.IDBConn(&ctxI)

	// Get all series names from input database
	res := lib.QueryIDB(ic, &ctxI, "show series")
	if len(res[0].Series) < 1 {
		lib.Printf("Nothing to copy\n")
		return
	}
	iSeries := res[0].Series[0].Values

	// Get unique series name (without tags)
	uniSeries := make(map[string]struct{})
	for _, ser := range iSeries {
		split := strings.Split(ser[0].(string), ",")
		uniSeries[split[0]] = struct{}{}
	}
	series := []string{}
	for ser := range uniSeries {
		series = append(series, ser)
	}
	nSeries := len(series)

	// Close connection
	lib.FatalOnError(ic.Close())

	//series[0] = "company_multi_cluster_issues_y"
	//nSeries = 1
	dtStart := time.Now()
	lastTime := dtStart
	checked := 0
	lib.Printf("Processing %d series\n", nSeries)

	// Copy series
	if thrN > 1 {
		ch := make(chan bool)
		nThreads := 0
		for i := 0; i < nSeries; i++ {
			go copySeries(ch, &ctxI, &ctxO, series[i])
			nThreads++
			if nThreads == thrN {
				<-ch
				nThreads--
				checked++
				lib.ProgressInfo(checked, nSeries, dtStart, &lastTime, time.Duration(10)*time.Second, "")
			}
		}
		lib.Printf("Final threads join\n")
		for nThreads > 0 {
			<-ch
			nThreads--
			checked++
			lib.ProgressInfo(checked, nSeries, dtStart, &lastTime, time.Duration(10)*time.Second, "final join...")
		}
	} else {
		lib.Printf("Using single threaded version\n")
		for i := 0; i < nSeries; i++ {
			copySeries(nil, &ctxI, &ctxO, series[i])
			lib.ProgressInfo(i, nSeries, dtStart, &lastTime, time.Duration(10)*time.Second, "")
		}
	}
	// Finished
	lib.Printf("All done.\n")
}

func main() {
	dtStart := time.Now()
	fmt.Printf(
		"Consider fresh restart of `influxd` service, this program temporarily doubles influxd memory usage.\n",
	)
	idbBackup()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
