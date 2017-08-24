package main

import (
	"fmt"
	"io/ioutil"
	lib "k8s.io/test-infra/gha2db"
	"os"
	"strings"
	"time"
)

func workerThread(ch chan bool, seriesNameOrFunc, sql, period string, from, to time.Time) {
	// Connect to Postgres DB
	sqlc := lib.Conn()
	defer sqlc.Close()
	ic, bp := lib.IDBConn()
	defer ic.Close()
	sFrom := lib.ToSQLDate(from)
	sTo := lib.ToSQLDate(to)
	fmt.Printf("%v, %v, %v\n", bp, sFrom, sTo)
	/*
			  s_from = from.to_s[0..-7]
			  s_to = to.to_s[0..-7]
			  q = sql.gsub('{{from}}', s_from).gsub('{{to}}', s_to)
			  r = exec_sql(sqlc, q)
			  return if r.count.zero?
			  # ts = (from.to_i + to.to_i) / 2
			  ts = from.to_i
			  # ts = to.to_i
			  if r.count == 1 && r.first.keys.count == 1
			    value = r.first.values.first.to_i
			    name = series_name_or_func
			    puts "#{from.to_date} - #{to.to_date} -> #{name}, #{value}" if $debug.positive?
			    data = {
			      values: { value: value },
			      timestamp: ts
			    }
			    ic.write_point(name, data)
			  elsif r.count.positive? && r.first.keys.count == 2
			    r.each do |row|
			      name, value = __send__(series_name_or_func, row, period)
			      puts "#{from.to_date} - #{to.to_date} -> #{name}, #{value}" if $debug.positive?
			      data = {
			        values: { value: value },
			        timestamp: ts
			      }
			      ic.write_point(name, data)
			    end
		      :else
			    raise(
			      Exception,
			      "Wrong query:\n#{q}\nMetrics query should either return single row "\
			      'with single value or at least 1 row, each with two values'
			    )
			  end
	*/
	if ch != nil {
		ch <- true
	}
}

func db2influx(seriesNameOrFunc, sqlFile, from, to, intervalAbbr string) {
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
	thrN := lib.GetThreadsNum()

	// Run
	fmt.Printf("Running (on %d CPUs): %v - %v with interval %s\n", thrN, dFrom, dTo, interval)
	dt := dFrom
	if thrN > 1 {
		chanPool := []chan bool{}
		for dt.Before(dTo) {
			ch := make(chan bool)
			chanPool = append(chanPool, ch)
			nDt := nextIntervalStart(dt)
			go workerThread(ch, seriesNameOrFunc, sqlQuery, intervalAbbr, dt, nDt)
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
			workerThread(nil, seriesNameOrFunc, sqlQuery, intervalAbbr, dt, nDt)
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
