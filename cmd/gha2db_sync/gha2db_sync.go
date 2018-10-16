package main

import (
	lib "devstats"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	yaml "gopkg.in/yaml.v2"
)

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
	MergeSeries       string `yaml:"merge_series"`
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

	// Get max event date from Postgres database
	var maxDtPtr *time.Time
	maxDtPg := ctx.DefaultStartDate
	if !ctx.ForceStartDate {
		lib.FatalOnError(lib.QueryRowSQL(con, ctx, "select max(dt) from gha_parsed").Scan(&maxDtPtr))
		if maxDtPtr != nil {
			maxDtPg = maxDtPtr.Add(1 * time.Hour)
		}
	}

	// Get max series date from TS database
	maxDtTSDB := ctx.DefaultStartDate
	if !ctx.ForceStartDate {
		table := "s" + ctx.LastSeries
		if lib.TableExists(con, ctx, table) {
			lib.FatalOnError(lib.QueryRowSQL(con, ctx, "select max(time) from "+table).Scan(&maxDtPtr))
			if maxDtPtr != nil {
				maxDtTSDB = *maxDtPtr
			}
		}
	}
	if ctx.Debug > 0 {
		lib.Printf("Using start dates: %v, %v\n", maxDtPg, maxDtTSDB)
	}

	// Create date range
	// Just to get into next GHA hour
	from := maxDtPg
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
		if !ctx.SkipGHAPI {
			lib.Printf("Update data from GitHub API\n")
			// Recompute views and DB summaries
			ctx.ExecFatal = false
			_, err = lib.ExecCommand(
				ctx,
				[]string{
					cmdPrefix + "ghapi2db",
				},
				nil,
			)
			ctx.ExecFatal = true
			if err != nil {
				lib.Printf("Error executing ghapi2db: %+v\n", err)
				fmt.Fprintf(os.Stderr, "Error executing ghapi2db: %+v\n", err)
			}
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

	// Calc metric
	if !ctx.SkipTSDB {
		metricsDir := dataPrefix + "metrics"
		if ctx.Project != "" {
			metricsDir += "/" + ctx.Project
		}
		// Regenerate points from this date
		if ctx.ResetTSDB {
			from = ctx.DefaultStartDate
		} else {
			from = maxDtTSDB
		}
		lib.Printf("TS range: %s - %s\n", lib.ToYMDHDate(from), lib.ToYMDHDate(to))

		// TSDB tags (repo groups template variable currently)
		if !ctx.SkipTags {
			if ctx.ResetTSDB || time.Now().Hour() == 0 {
				_, err := lib.ExecCommand(ctx, []string{cmdPrefix + "tags"}, nil)
				lib.FatalOnError(err)
			} else {
				lib.Printf("Skipping `tags` recalculation, it is only computed once per day\n")
			}
		}

		// Annotations
		if !ctx.SkipAnnotations {
			if ctx.Project != "" && (ctx.ResetTSDB || time.Now().Hour() == 0) {
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
		}

		// Get Quick Ranges from TSDB (it is filled by annotations command)
		quickRanges := lib.GetTagValues(con, ctx, "quick_ranges", "quick_ranges_suffix")
		lib.Printf("Quick ranges: %+v\n", quickRanges)

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
		onlyMetrics := false
		if len(ctx.OnlyMetrics) > 0 {
			onlyMetrics = true
		}

		// Iterate all metrics
		for _, metric := range allMetrics.Metrics {
			if onlyMetrics {
				_, ok := ctx.OnlyMetrics[metric.MetricSQL]
				if !ok {
					continue
				}
			}
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
			if metric.MergeSeries != "" {
				extraParams = append(extraParams, "merge_series:"+metric.MergeSeries)
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
			if !ctx.ResetTSDB && !ctx.ResetRanges {
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
					if (!ctx.ResetTSDB || ctx.ComputePeriods != nil) && !lib.ComputePeriodAtThisDate(ctx, period, to, metric.Histogram) {
						lib.Printf("Skipping recalculating period \"%s%s\", hist %v for date to %v\n", period, aggrSuffix, metric.Histogram, to)
						continue
					}
					seriesNameOrFunc := metric.SeriesNameOrFunc
					if metric.AddPeriodToName {
						seriesNameOrFunc += "_" + periodAggr
					}
					// Histogram metrics usualy take long time, but executes single query, so there is no way to
					// Implement multi threading inside "calc_metric" call for them
					// So we're creating array of such metrics to be executed at the end - each in a separate go routine
					if metric.Histogram {
						lib.Printf("Scheduled histogram metric %v, period %v, desc: '%v', aggregate: '%v' ...\n", metric.Name, period, metric.Desc, aggrSuffix)
						hists = append(
							hists,
							[]string{
								cmdPrefix + "calc_metric",
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
								cmdPrefix + "calc_metric",
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

		// TSDB ensure that calculated metric have all columns from tags
		if !ctx.SkipColumns {
			if ctx.ResetTSDB || time.Now().Hour() == 0 {
				_, err := lib.ExecCommand(ctx, []string{cmdPrefix + "columns"}, nil)
				lib.FatalOnError(err)
			} else {
				lib.Printf("Skipping `columns` recalculation, it is only computed once per day\n")
			}
		}
	}
	lib.Printf("Sync success\n")
}

// calcHistogram - calculate single histogram by calling "calc_metric" program with parameters from "hist"
func calcHistogram(ch chan bool, ctx *lib.Ctx, hist []string) {
	if len(hist) != 7 {
		lib.Fatalf("calcHistogram, expected 7 strings, got: %d: %v", len(hist), hist)
	}
	envMap := make(map[string]string)
	lib.Printf(
		"Calculate histogram %s,%s,%s,%s,%s,%s ...\n",
		hist[1],
		hist[2],
		hist[3],
		hist[4],
		hist[5],
		hist[6],
	)
	// Execute "calc_metric"
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

	// Are we running from "devstats" which already sets ENV from projects.yaml?
	envSet := os.Getenv("ENV_SET") != ""

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
		if !envSet && proj.Env != nil {
			for envK, envV := range proj.Env {
				if envK == "GHA2DB_EXCLUDE_REPOS" {
					if envV != "" {
						ctx.ExcludeRepos = make(map[string]bool)
						excludeArray := strings.Split(envV, ",")
						for _, exclude := range excludeArray {
							if exclude != "" {
								ctx.ExcludeRepos[exclude] = true
							}
						}
						lib.Printf("Exclude repos config from env: %+v\n", ctx.ExcludeRepos)
					} else {
						lib.Fatalf("empty '%s', do not specify at all instead", envK)
					}
				} else {
					lib.Fatalf("don't know how to apply env: '%s' = '%s'", envK, envV)
				}
			}
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
