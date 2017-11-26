package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"strconv"
	"strings"
	"time"

	lib "devstats"

	yaml "gopkg.in/yaml.v2"
)

// gaps contain list of metrics to fill gaps
type gaps struct {
	Metrics []metricGap `yaml:"metrics"`
}

// metricGap conain list of series names and periods to fill gaps
// Series formula allows writing a lot of series name in a shorter way
// Say we have series in this form prefix_{x}_{y}_{z}_suffix
// and {x} can be a,b,c,d, {y} can be 1,2,3, z can be yes,no
// Instead of listing all combinations prefix_a_1_yes_suffix, ..., prefix_d_3_no_suffix
// Which is 4 * 3 * 2 = 24 items, You can write series formula:
// "=prefix;suffix;_;a,b,c,d;1,2,3;yes,no"
// format is "=prefix;suffix;join;list1item1,list1item2,...;list2item1,list2item2,...;..."
// Values can be set the same way as Series, it is the array of series properties to clear
// If not specified, ["value"] is assumed - it is used for multi-value series
type metricGap struct {
	Name      string   `yaml:"name"`
	Series    []string `yaml:"series"`
	Periods   string   `yaml:"periods"`
	Aggregate string   `yaml:"aggregate"`
	Skip      string   `yaml:"skip"`
	Desc      bool     `yaml:"desc"`
	Values    []string `yaml:"values"`
}

// metrics contain list of metrics to evaluate
type metrics struct {
	Metrics []metric `yaml:"metrics"`
}

// metric contain each metric data
type metric struct {
	Name              string `yaml:"name"`
	Periods           string `yaml:"periods"`
	SeriesNameOrFunc  string `yaml:"series_name_or_func"`
	MetricSQL         string `yaml:"sql"`
	AddPeriodToName   bool   `yaml:"add_period_to_name"`
	Histogram         bool   `yaml:"histogram"`
	Aggregate         string `yaml:"aggregate"`
	Skip              string `yaml:"skip"`
	Desc              string `yaml:"desc"`
	MultiValue        bool   `yaml:"multi_value"`
	EscapeValueName   bool   `yaml:"escape_value_name"`
	AnnotationsRanges bool   `yaml:"annotations_ranges"`
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
	var gaps gaps

	// Local or cron mode?
	cmdPrefix := ""
	dataPrefix := lib.DataDir
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
		extraParams := []string{}
		if metric.Desc {
			extraParams = append(extraParams, "desc")
		}
		// Parse multi values
		values := []string{}
		for _, value := range metric.Values {
			if value[0:1] == "=" {
				valuesArr := createSeriesFromFormula(value)
				values = append(values, valuesArr...)
			} else {
				values = append(values, value)
			}
		}
		if len(values) == 0 {
			values = append(values, "value")
		}
		extraParams = append(extraParams, "values:"+strings.Join(values, ";"))
		// Parse series
		series := []string{}
		for _, ser := range metric.Series {
			if ser[0:1] == "=" {
				formulaSeries := createSeriesFromFormula(ser)
				series = append(series, formulaSeries...)
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
		aggregate := metric.Aggregate
		if aggregate == "" {
			aggregate = "1"
		}
		aggregateArr := strings.Split(aggregate, ",")
		skips := strings.Split(metric.Skip, ",")
		skipMap := make(map[string]struct{})
		for _, skip := range skips {
			skipMap[skip] = struct{}{}
		}
		for _, aggrStr := range aggregateArr {
			_, err := strconv.Atoi(aggrStr)
			lib.FatalOnError(err)
			aggrSuffix := aggrStr
			if aggrSuffix == "1" {
				aggrSuffix = ""
			}
			for _, period := range periods {
				periodAggr := period + aggrSuffix
				_, found := skipMap[periodAggr]
				if found {
					lib.Printf("Skipped filling gaps on period %s\n", periodAggr)
					continue
				}
				if !ctx.ResetIDB && !computePeriodAtThisDate(period, to) {
					lib.Printf("Skipping filling gaps for period \"%s\" for date %v\n", periodAggr, to)
					continue
				}
				for i := 0; i < nBuckets; i++ {
					bFrom := i * bSize
					bTo := bFrom + bSize
					if bTo > nSeries {
						bTo = nSeries
					}
					lib.Printf("Filling metric gaps %v, descriptions %v, period: %s, %d series (%d - %d)...\n", metric.Name, metric.Desc, periodAggr, nSeries, bFrom, bTo)
					lib.ExecCommand(
						ctx,
						[]string{
							cmdPrefix + "z2influx",
							strings.Join(addPeriodSuffix(series[bFrom:bTo], periodAggr), ","),
							lib.ToYMDHDate(from),
							lib.ToYMDHDate(to),
							periodAggr,
							strings.Join(extraParams, ","),
						},
						nil,
					)
				}
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

func sync(ctx *lib.Ctx, args []string) {
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
	dataPrefix := lib.DataDir
	if ctx.Local {
		cmdPrefix = "./"
		dataPrefix = "./"
	}

	// Connect to Postgres DB
	con := lib.PgConn(ctx)
	defer con.Close()

	// Connect to InfluxDB
	ic := lib.IDBConn(ctx)
	defer ic.Close()

	// Get max event date from Postgres database
	var maxDtPtr *time.Time
	maxDtPg := ctx.DefaultStartDate
	lib.FatalOnError(lib.QueryRowSQL(con, ctx, "select max(created_at) from gha_events").Scan(&maxDtPtr))
	if maxDtPtr != nil {
		maxDtPg = *maxDtPtr
	}

	// Get max series date from Influx database
	maxDtIDB := ctx.DefaultStartDate
	res := lib.QueryIDB(ic, ctx, "select last(value) from "+ctx.LastSeries)
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
		// Clear old DB logs
		lib.ClearDBLogs()

		// gha2db
		lib.Printf("GHA range: %s %s - %s %s\n", fromDate, fromHour, toDate, toHour)
		lib.ExecCommand(
			ctx,
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
			ctx,
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
		if ctx.Project != "" {
			metricsDir += "/" + ctx.Project
		}
		// Regenerate points from this date
		if ctx.ResetIDB {
			from = ctx.DefaultStartDate
		} else {
			from = maxDtIDB
		}
		lib.Printf("Influx range: %s - %s\n", lib.ToYMDHDate(from), lib.ToYMDHDate(to))

		// InfluxDB tags (repo groups template variable currently)
		if ctx.ResetIDB || time.Now().Hour() == 0 {
			lib.ExecCommand(ctx, []string{cmdPrefix + "idb_tags"}, nil)
		} else {
			lib.Printf("Skipping `idb_tags` recalculation, it is only computed once per day\n")
		}

		// Annotations
		if ctx.ResetIDB || time.Now().Hour() == 0 {
			lib.ExecCommand(
				ctx,
				[]string{
					cmdPrefix + "annotations",
					lib.ToYMDHDate(from),
				},
				nil,
			)
		} else {
			lib.Printf("Skipping `annotations` recalculation, it is only computed once per day\n")
		}

		// Get Quick Ranges from IDB (it is filled by annotations command)
		quickRanges := lib.GetTagValues(ic, ctx, "quick_ranges_suffix")
		lib.Printf("Quick ranges: %+v\n", quickRanges)

		// Fill gaps in series
		fillGapsInSeries(ctx, from, to)

		// Read metrics configuration
		data, err := ioutil.ReadFile(dataPrefix + ctx.MetricsYaml)
		if err != nil {
			lib.FatalOnError(err)
			return
		}
		var allMetrics metrics
		lib.FatalOnError(yaml.Unmarshal(data, &allMetrics))

		// Iterate all metrics
		for _, metric := range allMetrics.Metrics {
			extraParams := []string{}
			if metric.Histogram {
				extraParams = append(extraParams, "hist")
			}
			if metric.MultiValue {
				extraParams = append(extraParams, "multivalue")
			}
			if metric.EscapeValueName {
				extraParams = append(extraParams, "escape_value_name")
			}
			if metric.Desc != "" {
				extraParams = append(extraParams, "desc:"+metric.Desc)
			}
			periods := strings.Split(metric.Periods, ",")
			aggregate := metric.Aggregate
			if aggregate == "" {
				aggregate = "1"
			}
			if metric.AnnotationsRanges {
				extraParams = append(extraParams, "annotations_ranges")
				periods = quickRanges
				aggregate = "1"
			}
			aggregateArr := strings.Split(aggregate, ",")
			skips := strings.Split(metric.Skip, ",")
			skipMap := make(map[string]struct{})
			for _, skip := range skips {
				skipMap[skip] = struct{}{}
			}
			if !ctx.ResetIDB && !ctx.ResetRanges {
				extraParams = append(extraParams, "skip_past")
			}
			for _, aggrStr := range aggregateArr {
				_, err := strconv.Atoi(aggrStr)
				lib.FatalOnError(err)
				aggrSuffix := aggrStr
				if aggrSuffix == "1" {
					aggrSuffix = ""
				}
				for _, period := range periods {
					periodAggr := period + aggrSuffix
					_, found := skipMap[periodAggr]
					if found {
						lib.Printf("Skipped period %s\n", periodAggr)
						continue
					}
					if !ctx.ResetIDB && !computePeriodAtThisDate(period, to) {
						lib.Printf("Skipping recalculating period \"%s%s\" for date to %v\n", period, aggrSuffix, to)
						continue
					}
					lib.Printf("Calculate metric %v, period %v, histogram: %v, desc: '%v', aggregate: '%v' ...\n", metric.Name, period, metric.Histogram, metric.Desc, aggrSuffix)
					seriesNameOrFunc := metric.SeriesNameOrFunc
					if metric.AddPeriodToName {
						seriesNameOrFunc += "_" + periodAggr
					}
					lib.ExecCommand(
						ctx,
						[]string{
							cmdPrefix + "db2influx",
							seriesNameOrFunc,
							fmt.Sprintf("%s/%s.sql", metricsDir, metric.MetricSQL),
							lib.ToYMDHDate(from),
							lib.ToYMDHDate(to),
							periodAggr,
							strings.Join(extraParams, ","),
						},
						nil,
					)
				}
			}
		}
	}
	lib.Printf("Sync success\n")
}

// Return per project args (if no args given) or get args from command line (if given)
// When no args given and no project set (via GHA2DB_PROJECT) it panics
func getSyncArgs(ctx *lib.Ctx, osArgs []string) []string {
	// User commandline override
	if len(osArgs) > 1 {
		return osArgs[1:]
	}

	// No user commandline, get args specific to project GHA2DB_PROJECT
	if ctx.Project == "" {
		lib.FatalOnError(fmt.Errorf(
			"you have to set project via GHA2DB_PROJECT environment variable if you provide no commandline arguments",
		),
		)
	}
	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read defined projects
	data, err := ioutil.ReadFile(dataPrefix + "projects.yaml")
	if err != nil {
		lib.FatalOnError(err)
		return []string{}
	}
	var projs lib.Projects
	lib.FatalOnError(yaml.Unmarshal(data, &projs))
	for _, proj := range projs.Projects {
		if proj.Name == ctx.Project {
			if proj.StartDate != nil {
				ctx.DefaultStartDate = *proj.StartDate
			}
			return []string{proj.CommandLine}
		}
	}
	// No user commandline and project not found
	lib.FatalOnError(
		fmt.Errorf(
			"project %s is not defined in projects.yaml",
			ctx.Project,
		),
	)
	return []string{}
}

func main() {
	dtStart := time.Now()
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()
	sync(&ctx, getSyncArgs(&ctx, os.Args))
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
