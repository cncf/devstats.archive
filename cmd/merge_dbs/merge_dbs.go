package main

import (
	"database/sql"
	lib "devstats"
	"fmt"
	"time"

	"github.com/lib/pq"
)

func mergePDBs() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	if len(ctx.InputDBs) < 1 {
		lib.Fatalf("required at least 1 input database, got %d: %+v", len(ctx.InputDBs), ctx.InputDBs)
		return
	}
	if ctx.OutputDB == "" {
		lib.Fatalf("output database required")
		return
	}

	// Connect to input Postgres DBs
	ci := []*sql.DB{}
	iNames := []string{}
	for _, iName := range ctx.InputDBs {
		c := lib.PgConnDB(&ctx, iName)
		ci = append(ci, c)
		iNames = append(iNames, iName)
	}

	// Defer closing all input connections
	defer func() {
		for _, c := range ci {
			lib.FatalOnError(c.Close())
		}
	}()

	// Connect to the output Postgres DB
	co := lib.PgConnDB(&ctx, ctx.OutputDB)
	// Defer close output connection
	defer func() { lib.FatalOnError(co.Close()) }()

	// process this tables
	// 1st pass uses 1st condition
	// 2nd pass uses 2nd condition
	// "-" means that this pass is skipped
	// Some tables are commented out because we're going to
	// run other tools on merged database to fill them
	tableData := [][]string{
		{"gha_actors", "id > 0", "id <= 0"},
		//{"gha_actors_affiliations", "", "-"},
		//{"gha_actors_emails", "", "-"},
		{"gha_assets", "", "-"},
		{"gha_branches", "", "-"},
		{"gha_comments", "", "-"},
		{"gha_commits", "", "-"},
		{"gha_commits_files", "", "-"},
		//{"gha_companies", "", "-"},
		//{"gha_computed", "", "-"},
		{"gha_events", "id > 0", "id <= 0"},
		//{"gha_events_commits_files", "", "-"},
		{"gha_forkees", "", "-"},
		{"gha_issues", "id > 0", "id <= 0"},
		{"gha_issues_assignees", "", "-"},
		{"gha_issues_events_labels", "", "-"},
		{"gha_issues_labels", "", "-"},
		{"gha_issues_pull_requests", "", "-"},
		{"gha_labels", "id > 0", "id <= 0"},
		//{"gha_logs", "", "-"},
		{"gha_milestones", "", "-"},
		{"gha_orgs", "", "-"},
		{"gha_pages", "", "-"},
		{"gha_payloads", "event_id > 0", "event_id <= 0"},
		//{"gha_postprocess_scripts", "", "-"},
		{"gha_pull_requests", "", "-"},
		{"gha_pull_requests_assignees", "", "-"},
		{"gha_pull_requests_requested_reviewers", "", "-"},
		{"gha_releases", "", "-"},
		{"gha_releases_assets", "", "-"},
		{"gha_repos", "", "-"},
		{"gha_skip_commits", "", "-"},
		{"gha_teams", "", "-"},
		{"gha_teams_repositories", "", "-"},
		{"gha_texts", "", "-"},
		{"gha_parsed", "", "-"},
	}

	for pass, passInfo := range []string{"1st pass", "2nd pass"} {
		for i, data := range tableData {
			table := data[0]
			cond := data[pass+1]
			if cond == "-" {
				continue
			}
			allRows := 0
			allErrs := 0
			allIns := 0
			for dbi, c := range ci {
				// First get row count
				rc := 0
				queryRoot := "from " + table
				if cond != "" {
					queryRoot += " where " + cond
				}
				row := c.QueryRow("select count(*) " + queryRoot)
				lib.FatalOnError(row.Scan(&rc))

				// Now get all data
				lib.Printf(
					"%s: start table: #%d: %s, DB #%d: %s, rows: %d...\n",
					passInfo, i, table, dbi, iNames[dbi], rc,
				)
				rows := lib.QuerySQLWithErr(
					c,
					&ctx,
					"select * "+queryRoot,
				)
				//defer func() { lib.FatalOnError(rows.Close()) }()
				// Now unknown rows, with unknown types
				columns, err := rows.Columns()
				lib.FatalOnError(err)

				// Vals to hold any type as []interface{}
				nColumns := len(columns)
				vals := make([]interface{}, nColumns)
				for i := range columns {
					vals[i] = new(interface{})
				}

				// Get results into `results` array of maps
				rowCount := 0
				errCount := 0
				insCount := 0
				// For ProgressInfo()
				dtStart := time.Now()
				lastTime := dtStart
				for rows.Next() {
					lib.FatalOnError(rows.Scan(vals...))
					_, err := lib.ExecSQL(
						co,
						&ctx,
						"insert into "+table+" "+lib.NValues(nColumns),
						vals...,
					)
					if err != nil {
						switch e := err.(type) {
						case *pq.Error:
							if e.Code.Name() != "unique_violation" {
								lib.FatalOnError(err)
							}
						default:
							lib.FatalOnError(err)
						}
						errCount++
					} else {
						insCount++
					}
					rowCount++
					lib.ProgressInfo(
						rowCount, rc, dtStart, &lastTime, time.Duration(10)*time.Second,
						fmt.Sprintf("%s: table #%d %s, DB #%d %s", passInfo, i, table, dbi, iNames[dbi]),
					)
				}
				lib.FatalOnError(rows.Err())
				lib.FatalOnError(rows.Close())
				perc := 0.0
				if rowCount > 0 {
					perc = float64(errCount) * 100.0 / (float64(rowCount))
				}
				lib.Printf(
					"%s: done table: #%d: %s, DB #%d: %s, rows: %d, inserted: %d, collisions: %d (%.3f%%)\n",
					passInfo, i, table, dbi, iNames[dbi], rowCount, insCount, errCount, perc,
				)
				allRows += rowCount
				allErrs += errCount
				allIns += insCount
			}
			perc := 0.0
			if allRows > 0 {
				perc = float64(allErrs) * 100.0 / (float64(allRows))
			}
			lib.Printf(
				"%s: done table: #%d: %s, all rows: %d, inserted: %d, collisions: %d (%.3f%%)\n",
				passInfo, i, table, allRows, allIns, allErrs, perc,
			)
		}
	}
}

func main() {
	dtStart := time.Now()
	mergePDBs()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
	fmt.Printf("Consider running './devel/remove_db_dups.sh' if you merged into existing database.\n")
}
