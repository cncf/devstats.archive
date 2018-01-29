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

	if len(ctx.InputDBs) < 2 {
		lib.FatalOnError(fmt.Errorf("required at least 2 input databases, got %d: %+v", len(ctx.InputDBs), ctx.InputDBs))
		return
	}
	if ctx.OutputDB == "" {
		lib.FatalOnError(fmt.Errorf("required at least output database"))
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
	tables := []string{
		"gha_actors",
	}

	for i, table := range tables {
		allRows := 0
		allErrs := 0
		allIns := 0
		for dbi, c := range ci {
			// First get row count
			rc := 0
			row := c.QueryRow("select count(*) from " + table)
			lib.FatalOnError(row.Scan(&rc))

			// Now get all data
			lib.Printf(
				"Start table: #%d: %s, DB #%d: %s, rows: %d...\n",
				i, table, dbi, iNames[dbi], rc,
			)
			rows := lib.QuerySQLWithErr(
				c,
				&ctx,
				"select * from "+table,
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
					fmt.Sprintf("Table #%d %s, DB #%d %s", i, table, dbi, iNames[dbi]),
				)
			}
			lib.FatalOnError(rows.Err())
			lib.FatalOnError(rows.Close())
			perc := 0.0
			if rowCount > 0 {
				perc = float64(errCount) * 100.0 / (float64(rowCount))
			}
			lib.Printf(
				"Done table: #%d: %s, DB #%d: %s, rows: %d, inserted: %d, collisions: %d (%.3f%%)\n",
				i, table, dbi, iNames[dbi], rowCount, insCount, errCount, perc,
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
			"Done table: #%d: %s, all rows: %d, inserted: %d, collisions: %d (%.3f%%)\n",
			i, table, allRows, allIns, allErrs, perc,
		)
	}
}

func main() {
	dtStart := time.Now()
	mergePDBs()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
