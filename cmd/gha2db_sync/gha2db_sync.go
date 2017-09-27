package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"time"

	lib "gha2db"

	yaml "gopkg.in/yaml.v2"
)

// Gaps contain list of metrics to fill gaps
type Gaps struct {
	Metrics []MetricGap `yaml:"metrics"`
}

// MetricGap conain list of series names and periods to fill gaps
// Series formula allows writing a lot of series name in a shorter way
// Say we have series in this form prefix_{x}_{y}_{z}_suffix
// and {x} can be a,b,c,d, {y} can be 1,2,3, z can be yes,no
// Instead of listing all combinations prefix_a_1_yes_suffix, ..., prefix_d_3_no_suffix
// Which is 4 * 3 * 2 = 24 items, You can write series formula:
// "=prefix;suffix;_;a,b,c,d;1,2,3;yes,no"
// format is "=prefix;suffix;join;list1item1,list1item2,...;list2item1,list2item2,...;..."
type MetricGap struct {
	Name    string   `yaml:"name"`
	Series  []string `yaml:"series"`
	Periods string   `yaml:"periods"`
}

// Metrics contain list of metrics to evaluate
type Metrics struct {
	Metrics []Metric `yaml:"metrics"`
}

// Metric contain each metric data
type Metric struct {
	Name             string `yaml:"name"`
	Periods          string `yaml:"periods"`
	SeriesNameOrFunc string `yaml:"series_name_or_func"`
	MetricSQL        string `yaml:"sql"`
	AddPeriodToName  bool   `yaml:"add_period_to_name"`
	Histogram        bool   `yaml:"histogram"`
	Aggregate        string `yaml:"aggregate"`
}

// Add _period to all array items
func addPeriodSuffix(seriesArr []string, period string) (result []string) {
	for _, series := range seriesArr {
		result = append(result, series+"_"+period)
	}
	return
}

// Return cartesian product of all arrays starting with prefix, joined by "join" ending with suffix
func joinedCartesian(mat [][]string, prefix, join, suffix string) (result []string) {
	// rows - number of arrays to join, rowsm1 (last index of array to join)
	rows := len(mat)
	rowsm1 := rows - 1

	// lens[i] - i-th row length - 1 (last i-th row column index)
	// curr[i] - current position in i-th row, we're processing N x M x ... positions
	// All possible combinations = Cartesian
	var (
		lens []int
		curr []int
	)
	for _, row := range mat {
		lens = append(lens, len(row)-1)
		curr = append(curr, 0)
	}

	// While not for all i curr[i] == lens[i]
	for {
		// Create one of output combinations
		str := prefix
		for i := 0; i < rows; i++ {
			str += mat[i][curr[i]]
			if i < rowsm1 {
				str += join
			}
		}
		str += suffix
		result = append(result, str)

		// Stop if for all i curr[i] == lens[i]
		// Which means we processed all possible combinations
		stop := true
		for i := 0; i < rows; i++ {
			if curr[i] < lens[i] {
				stop = false
				break
			}
		}
		if stop {
			break
		}

		// increase curr[i] for some i
		for i := 0; i < rows; i++ {
			// We can move to next permutation at this i
			if curr[i] < lens[i] {
				curr[i]++
				break
			} else {
				// We have to go to another row and zero all lower positions
				for j := 0; j <= i; j++ {
					curr[j] = 0
				}
			}
		}
	}

	// Retunrs "result" containing all possible permutations
	return
}

// Parse formula in format "=prefix;suffix;join;list1item1,list1item2,...;list2item1,list2item2,...;..."
func createSeriesFromFormula(def string) (result []string) {
	ary := strings.Split(def[1:], ";")
	if len(ary) < 4 {
		lib.FatalOnError(fmt.Errorf(
			"series formula must have at least 4 paramaters: "+
				"prefix, suffix, join, list, %v",
			def,
		))
	}

	// prefix, join value (how to connect strings from different arrays), suffix
	prefix, suffix, join := ary[0], ary[1], ary[2]

	// Create "matrix" of strings (not a real matrix because rows can have different counts)
	var matrix [][]string
	for _, list := range ary[3:] {
		vals := strings.Split(list, ",")
		matrix = append(matrix, vals)
	}

	// Create cartesian result with all possible combinations
	result = joinedCartesian(matrix, prefix, join, suffix)
	return
}

// fills series gaps
// Reads config from YAML (which series, for which periods)
func fillGapsInSeries(ctx *lib.Ctx, from, to time.Time) {
	lib.Printf("Fill gaps in series\n")
	var gaps Gaps

	// Local or cron mode?
	cmdPrefix := ""
	dataPrefix := "/etc/gha2db/"
	if ctx.Local {
		cmdPrefix = "./"
		dataPrefix = "./"
	}

	data, err := ioutil.ReadFile(dataPrefix + ctx.GapsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	lib.FatalOnError(yaml.Unmarshal(data, &gaps))

	// Iterate metrics and periods
	bSize := 1000
	for _, metric := range gaps.Metrics {
		series := []string{}
		for _, ser := range metric.Series {
			if ser[0:1] == "=" {
				formulaSeries := createSeriesFromFormula(ser)
				for _, formulaSer := range formulaSeries {
					series = append(series, formulaSer)
				}
			} else {
				series = append(series, ser)
			}
		}
		nSeries := len(series)
		nBuckets := nSeries / bSize
		if nSeries%bSize > 0 {
			nBuckets++
		}
		periods := strings.Split(metric.Periods, ",")
		for _, period := range periods {
			if !ctx.ResetIDB && !computePeriodAtThisDate(period, to) {
				lib.Printf("Skipping filling gaps for period \"%s\" for date %v\n", period, to)
				continue
			}
			for i := 0; i < nBuckets; i++ {
				bFrom := i * bSize
				bTo := bFrom + bSize
				if bTo > nSeries {
					bTo = nSeries
				}
				lib.Printf("Filling metric gaps %v, %d series (%d - %d)...\n", metric.Name, nSeries, bFrom, bTo)
				lib.ExecCommand(
					ctx,
					[]string{
						cmdPrefix + "z2influx",
						strings.Join(addPeriodSuffix(series[bFrom:bTo], period), ","),
						lib.ToYMDHDate(from),
						lib.ToYMDHDate(to),
						period,
					},
					nil,
				)
			}
		}
	}
}

// computePeriodAtThisDate - for some longer periods, only recalculate them on specific dates
func computePeriodAtThisDate(period string, to time.Time) bool {
	to = lib.HourStart(to)
	if period == "h" || period == "d" || period == "w" {
		return true
	} else if period == "m" || period == "q" || period == "y" {
		return to.Hour() == 0
	} else {
		return false
	}
}

func sync(args []string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Strip function to be used by MapString
	stripFunc := func(x string) string { return strings.TrimSpace(x) }

	// Orgs & Repos
	sOrg := ""
	if len(args) > 0 {
		sOrg = args[0]
	}
	sRepo := ""
	if len(args) > 1 {
		sRepo = args[1]
	}
	org := lib.StringsMapToArray(stripFunc, strings.Split(sOrg, ","))
	repo := lib.StringsMapToArray(stripFunc, strings.Split(sRepo, ","))
	lib.Printf("gha2db_sync.go: Running on: %s/%s\n", strings.Join(org, "+"), strings.Join(repo, "+"))

	// Local or cron mode?
	cmdPrefix := ""
	dataPrefix := "/etc/gha2db/"
	if ctx.Local {
		cmdPrefix = "./"
		dataPrefix = "./"
	}

	// Connect to Postgres DB
	con := lib.PgConn(&ctx)
	defer con.Close()

	// Connect to InfluxDB
	ic := lib.IDBConn(&ctx)
	defer ic.Close()

	// Get max event date from Postgres database
	var maxDtPtr *time.Time
	maxDtPg := ctx.DefaultStartDate
	lib.FatalOnError(lib.QueryRowSQL(con, &ctx, "select max(created_at) from gha_events").Scan(&maxDtPtr))
	if maxDtPtr != nil {
		maxDtPg = *maxDtPtr
	}

	// Get max series date from Influx database
	maxDtIDB := ctx.DefaultStartDate
	res := lib.QueryIDB(ic, &ctx, "select last(value) from "+ctx.LastSeries)
	series := res[0].Series
	if len(series) > 0 {
		maxDtIDB = lib.TimeParseIDB(series[0].Values[0][0].(string))
	}

	// Create date range
	// Just to get into next GHA hour
	from := maxDtPg.Add(5 * time.Minute)
	to := time.Now()
	fromDate := lib.ToYMDDate(from)
	fromHour := strconv.Itoa(from.Hour())
	toDate := lib.ToYMDDate(to)
	toHour := strconv.Itoa(to.Hour())

	// Get new GHAs
	if !ctx.SkipPDB {
		lib.Printf("GHA range: %s %s - %s %s\n", fromDate, fromHour, toDate, toHour)
		lib.ExecCommand(
			&ctx,
			[]string{
				cmdPrefix + "gha2db",
				fromDate,
				fromHour,
				toDate,
				toHour,
				strings.Join(org, ","),
				strings.Join(repo, ","),
			},
			nil,
		)

		lib.Printf("Update structure\n")
		// Recompute views and DB summaries
		lib.ExecCommand(
			&ctx,
			[]string{
				cmdPrefix + "structure",
			},
			map[string]string{
				"GHA2DB_SKIPTABLE": "1",
				"GHA2DB_MGETC":     "y",
			},
		)
	}

	// DB2Influx
	if !ctx.SkipIDB {
		metricsDir := dataPrefix + "metrics"
		// Regenerate points from this date
		if ctx.ResetIDB {
			from = ctx.DefaultStartDate
		} else {
			from = maxDtIDB
		}
		lib.Printf("Influx range: %s - %s\n", lib.ToYMDHDate(from), lib.ToYMDHDate(to))

		// Annotations
		lib.ExecCommand(
			&ctx,
			[]string{
				cmdPrefix + "annotations",
				lib.ToYMDHDate(from),
			},
			nil,
		)

		// Fill gaps in series
		fillGapsInSeries(&ctx, from, to)

		// Read metrics configuration
		data, err := ioutil.ReadFile(dataPrefix + ctx.MetricsYaml)
		if err != nil {
			lib.FatalOnError(err)
			return
		}
		var allMetrics Metrics
		lib.FatalOnError(yaml.Unmarshal(data, &allMetrics))

		// Iterate all metrics
		for _, metric := range allMetrics.Metrics {
			histParam := ""
			if metric.Histogram {
				histParam = "h"
			}
			periods := strings.Split(metric.Periods, ",")
			aggregate := metric.Aggregate
			if aggregate == "" {
				aggregate = "1"
			}
			aggregateArr := strings.Split(aggregate, ",")
			for _, aggrStr := range aggregateArr {
				_, err := strconv.Atoi(aggrStr)
				lib.FatalOnError(err)
				aggrSuffix := aggrStr
				if aggrSuffix == "1" {
					aggrSuffix = ""
				}
				for _, period := range periods {
					if !ctx.ResetIDB && !computePeriodAtThisDate(period, to) {
						lib.Printf("Skipping recalculating period \"%s\" for date to %v\n", period, to)
						continue
					}
					lib.Printf("Calculate metric %v, period %v, histogram: %v, aggregate: '%v' ...\n", metric.Name, period, metric.Histogram, aggrSuffix)
					seriesNameOrFunc := metric.SeriesNameOrFunc
					if metric.AddPeriodToName {
						seriesNameOrFunc += "_" + period
					}
					lib.ExecCommand(
						&ctx,
						[]string{
							cmdPrefix + "db2influx",
							seriesNameOrFunc,
							fmt.Sprintf("%s/%s.sql", metricsDir, metric.MetricSQL),
							lib.ToYMDHDate(from),
							lib.ToYMDHDate(to),
							period + aggrSuffix,
							histParam,
						},
						nil,
					)
				}
			}
		}
	}
	lib.Printf("Sync success\n")
}

func main() {
	dtStart := time.Now()
	sync(os.Args[1:])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
