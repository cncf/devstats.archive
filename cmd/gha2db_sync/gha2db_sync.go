package main

import (
	"fmt"
	"math/rand"
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
		lib.Fatalf(
			"series formula must have at least 4 paramaters: "+
				"prefix, suffix, join, list, %v",
			def,
		)
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

	data, err := lib.ReadFile(ctx, dataPrefix+ctx.GapsYaml)
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
				if !ctx.ResetIDB && !lib.ComputePeriodAtThisDate(ctx, period, to) {
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
					_, err := lib.ExecCommand(
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
					lib.FatalOnError(err)
				}
			}
		}
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
	defer func() { lib.FatalOnError(con.Close()) }()

	// Connect to InfluxDB
	ic := lib.IDBConn(ctx)
	defer func() { lib.FatalOnError(ic.Close()) }()

	// Get max event date from Postgres database
	var maxDtPtr *time.Time
	maxDtPg := ctx.DefaultStartDate
	if !ctx.ForceStartDate {
		lib.FatalOnError(lib.QueryRowSQL(con, ctx, "select max(created_at) from gha_events").Scan(&maxDtPtr))
		if maxDtPtr != nil {
			maxDtPg = *maxDtPtr
		}
	}

	// Get max series date from Influx database
	maxDtIDB := ctx.DefaultStartDate
	if !ctx.ForceStartDate {
		res := lib.QueryIDB(ic, ctx, "select last(value) from "+ctx.LastSeries)
		series := res[0].Series
		if len(series) > 0 {
			maxDtIDB = lib.TimeParseIDB(series[0].Values[0][0].(string))
		}
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
		_, err := lib.ExecCommand(
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
		lib.FatalOnError(err)

		// Only run commits analysis for current DB here
		// We have updated repos to the newest state as 1st step in "devstats" call
		// We have also fetched all data from current GHA hour using "gha2db"
		// Now let's update new commits files (from newest hour)
		if !ctx.SkipGetRepos {
			lib.Printf("Update git commits\n")
			_, err = lib.ExecCommand(
				ctx,
				[]string{
					cmdPrefix + "get_repos",
				},
				map[string]string{
					"GHA2DB_PROCESS_COMMITS":  "1",
					"GHA2DB_PROJECTS_COMMITS": ctx.Project,
				},
			)
			lib.FatalOnError(err)
		}

		// GitHub API calls to get open issues state
		// It updates milestone and/or label(s) when different sice last comment state
		if !ctx.SkipGHAPI || !ctx.SkipArtificailClean {
			lib.Printf("Update data from GitHub API\n")
			// Recompute views and DB summaries
			_, err = lib.ExecCommand(
				ctx,
				[]string{
					cmdPrefix + "ghapi2db",
				},
				nil,
			)
			lib.FatalOnError(err)
		}

		// Eventual postprocess SQL's from 'structure' call
		lib.Printf("Update structure\n")
		// Recompute views and DB summaries
		_, err = lib.ExecCommand(
			ctx,
			[]string{
				cmdPrefix + "structure",
			},
			map[string]string{
				"GHA2DB_SKIPTABLE": "1",
				"GHA2DB_MGETC":     "y",
			},
		)
		lib.FatalOnError(err)
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
			_, err := lib.ExecCommand(ctx, []string{cmdPrefix + "idb_tags"}, nil)
			lib.FatalOnError(err)
		} else {
			lib.Printf("Skipping `idb_tags` recalculation, it is only computed once per day\n")
		}

		// Annotations
		if ctx.Project != "" && (ctx.ResetIDB || time.Now().Hour() == 0) {
			_, err := lib.ExecCommand(
				ctx,
				[]string{
					cmdPrefix + "annotations",
				},
				nil,
			)
			lib.FatalOnError(err)
		} else {
			lib.Printf("Skipping `annotations` recalculation, it is only computed once per day\n")
		}

		// Get Quick Ranges from IDB (it is filled by annotations command)
		quickRanges := lib.GetTagValues(ic, ctx, "quick_ranges_suffix")
		lib.Printf("Quick ranges: %+v\n", quickRanges)

		// Fill gaps in series
		fillGapsInSeries(ctx, from, to)

		// Read metrics configuration
		data, err := lib.ReadFile(ctx, dataPrefix+ctx.MetricsYaml)
		if err != nil {
			lib.FatalOnError(err)
			return
		}
		var allMetrics metrics
		lib.FatalOnError(yaml.Unmarshal(data, &allMetrics))

		// Keep all histograms here
		var hists [][]string

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
					if !ctx.ResetIDB && !lib.ComputePeriodAtThisDate(ctx, period, to) {
						lib.Printf("Skipping recalculating period \"%s%s\" for date to %v\n", period, aggrSuffix, to)
						continue
					}
					seriesNameOrFunc := metric.SeriesNameOrFunc
					if metric.AddPeriodToName {
						seriesNameOrFunc += "_" + periodAggr
					}
					// Histogram metrics usualy take long time, but executes single query, so there is no way to
					// Implement multi threading inside "db2influx" call fro them
					// So we're creating array of such metrics to be executed at the end - each in a separate go routine
					if metric.Histogram {
						lib.Printf("Scheduled histogram metric %v, period %v, desc: '%v', aggregate: '%v' ...\n", metric.Name, period, metric.Desc, aggrSuffix)
						hists = append(
							hists,
							[]string{
								cmdPrefix + "db2influx",
								seriesNameOrFunc,
								fmt.Sprintf("%s/%s.sql", metricsDir, metric.MetricSQL),
								lib.ToYMDHDate(from),
								lib.ToYMDHDate(to),
								periodAggr,
								strings.Join(extraParams, ","),
							},
						)
					} else {
						lib.Printf("Calculate metric %v, period %v, desc: '%v', aggregate: '%v' ...\n", metric.Name, period, metric.Desc, aggrSuffix)
						_, err = lib.ExecCommand(
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
						lib.FatalOnError(err)
					}
				}
			}
		}
		// Process histograms (possibly MT)
		// Get number of CPUs available
		thrN := lib.GetThreadsNum(ctx)
		if thrN > 1 {
			lib.Printf("Now processing %d histograms using MT%d version\n", len(hists), thrN)
			ch := make(chan bool)
			nThreads := 0
			for _, hist := range hists {
				go calcHistogram(ch, ctx, hist)
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
			lib.Printf("Now processing %d histograms using ST version\n", len(hists))
			for _, hist := range hists {
				calcHistogram(nil, ctx, hist)
			}
		}
	}
	lib.Printf("Sync success\n")
}

// calcHistogram - calculate single histogram by calling "db2influx" program with parameters from "hist"
func calcHistogram(ch chan bool, ctx *lib.Ctx, hist []string) {
	if len(hist) != 7 {
		lib.Fatalf("calcHistogram, expected 7 strings, got: %d: %v", len(hist), hist)
	}
	envMap := make(map[string]string)
	rSrc := rand.NewSource(time.Now().UnixNano())
	rnd := rand.New(rSrc)
	if ctx.IDBDropProbN > 0 && rnd.Intn(ctx.IDBDropProbN) == 1 {
		envMap["GHA2DB_IDB_DROP_SERIES"] = "1"
	}
	lib.Printf(
		"Calculate histogram %s,%s,%s,%s,%s,%s ...\n",
		hist[1],
		hist[2],
		hist[3],
		hist[4],
		hist[5],
		hist[6],
	)
	// Execute "db2influx"
	_, err := lib.ExecCommand(
		ctx,
		[]string{
			hist[0],
			hist[1],
			hist[2],
			hist[3],
			hist[4],
			hist[5],
			hist[6],
		},
		envMap,
	)
	lib.FatalOnError(err)
	// Synchronize go routine
	if ch != nil {
		ch <- true
	}
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
		lib.Fatalf(
			"you have to set project via GHA2DB_PROJECT environment variable if you provide no commandline arguments",
		)
	}
	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read defined projects
	data, err := lib.ReadFile(ctx, dataPrefix+ctx.ProjectsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return []string{}
	}
	var projects lib.AllProjects
	lib.FatalOnError(yaml.Unmarshal(data, &projects))
	proj, ok := projects.Projects[ctx.Project]
	if ok {
		if proj.StartDate != nil && !ctx.ForceStartDate {
			ctx.DefaultStartDate = *proj.StartDate
		}
		return proj.CommandLine
	}
	// No user commandline and project not found
	lib.Fatalf(
		"project '%s' is not defined in '%s'",
		ctx.Project,
		ctx.ProjectsYaml,
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
