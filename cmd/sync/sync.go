package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"

	lib "k8s.io/test-infra/gha2db"
)

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
	fmt.Printf("sync.go: Running on: %s/%s\n", strings.Join(org, "+"), strings.Join(repo, "+"))

	// Connect to Postgres DB
	con := lib.PgConn(&ctx)
	defer con.Close()

	// Connect to InfluxDB
	ic, _ := lib.IDBConn(&ctx)
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
	fmt.Printf("GHA range: %s %s - %s %s\n", fromDate, fromHour, toDate, toHour)
	lib.ExecCommand(
		&ctx,
		[]string{
			"./gha2db",
			fromDate,
			fromHour,
			toDate,
			toHour,
			strings.Join(org, ","),
			strings.Join(repo, ","),
		},
		nil,
	)

	fmt.Printf("Update structure\n")
	// Recompute views and DB summaries
	lib.ExecCommand(
		&ctx,
		[]string{
			"./structure",
		},
		map[string]string{
			"GHA2DB_SKIPTABLE": "1",
			"GHA2DB_MGETC":     "1",
		},
	)

	// InfluxDB periods
	periodsFromHour := []string{"h", "d", "w", "m", "q", "y"}
	periodsFromDay := periodsFromHour[1:]

	// DB2Influx
	if !ctx.SkipIDB {
		metricsDir := "psql_metrics"
		// Regenerate points from this date
		if ctx.ResetIDB {
			from = ctx.DefaultStartDate
		} else {
			from = maxDtIDB
		}
		fmt.Printf("Influx range: %s - %s\n", lib.ToYMDHDate(from), lib.ToYMDHDate(to))

		// Metrics from daily to yearly
		for _, period := range periodsFromDay {
			// Reviewers daily, weekly, monthly, quarterly, yearly
			lib.ExecCommand(
				&ctx,
				[]string{
					"./db2influx",
					"reviewers_" + period,
					metricsDir + "/reviewers.sql",
					lib.ToYMDDate(from),
					lib.ToYMDDate(to),
					period,
				},
				nil,
			)

			// SIG mentions daily, weekly, monthly, quarterly, yearly
			lib.ExecCommand(
				&ctx,
				[]string{
					"./db2influx",
					"sig_mentions_data",
					metricsDir + "/sig_mentions.sql",
					lib.ToYMDDate(from),
					lib.ToYMDDate(to),
					period,
				},
				nil,
			)

			// PRs merged per repo daily, weekly, monthly, quarterly, yearly
			lib.ExecCommand(
				&ctx,
				[]string{
					"./db2influx",
					"prs_merged_data",
					metricsDir + "/prs_merged.sql",
					lib.ToYMDDate(from),
					lib.ToYMDDate(to),
					period,
				},
				nil,
			)

			// Time opened to merged (number of hours) daily, weekly, monthly, quarterly, yearly
			lib.ExecCommand(
				&ctx,
				[]string{
					"./db2influx",
					"hours_pr_open_to_merge_" + period,
					metricsDir + "/opened_to_merged.sql",
					lib.ToYMDDate(from),
					lib.ToYMDDate(to),
					period,
				},
				nil,
			)
		}

		// Metrics that include hourly data
		for _, period := range periodsFromHour {
			// All PRs merged hourly, daily, weekly, monthly, quarterly, yearly
			lib.ExecCommand(
				&ctx,
				[]string{
					"./db2influx",
					"all_prs_merged_" + period,
					metricsDir + "/all_prs_merged.sql",
					lib.ToYMDHMSDate(from),
					lib.ToYMDHMSDate(to),
					period,
				},
				nil,
			)
		}
	}
	fmt.Printf("Sync success\n")
}

func main() {
	sync(os.Args[1:])
}
