package main

import (
	lib "devstats"
	"fmt"
	"time"

	yaml "gopkg.in/yaml.v2"
)

// columns contains list of columns that must be present on a certain series
type columns struct {
	Columns []column `yaml:"columns"`
}

// column contain configuration of columns needed on a specific series
type column struct {
	TableRegexp string `yaml:"table_regexp"`
	Tag         string `yaml:"tag"`
	Column      string `yaml:"column"`
}

// Ensure that specific TSDB series have all needed columns
func ensureColumns() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// If skip TSDB or only ES output - nothing to do
	if ctx.SkipTSDB || ctx.UseESOnly {
		return
	}

	// Connect to Postgres DB
	con := lib.PgConn(&ctx)
	defer func() { lib.FatalOnError(con.Close()) }()

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read columns config
	data, err := lib.ReadFile(&ctx, dataPrefix+ctx.ColumnsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	var allColumns columns
	lib.FatalOnError(yaml.Unmarshal(data, &allColumns))

	// Per project directory for SQL files
	dir := lib.Metrics
	if ctx.Project != "" {
		dir += ctx.Project + "/"
	}

	thrN := lib.GetThreadsNum(&ctx)
	ch := make(chan bool)
	nThreads := 0
	// Use integer index to pass to go rountine
	for i := range allColumns.Columns {
		go func(ch chan bool, idx int) {
			// Refer to current column config using index passed to anonymous function
			col := &allColumns.Columns[idx]
			if ctx.Debug > 0 {
				lib.Printf("Ensure column config: %+v\n", col)
			}
			crows := lib.QuerySQLWithErr(
				con,
				&ctx,
				fmt.Sprintf(
					"select \"%s\" from \"%s\"",
					col.Column,
					col.Tag,
				),
			)
			defer func() { lib.FatalOnError(crows.Close()) }()
			colName := ""
			colNames := []string{}
			for crows.Next() {
				lib.FatalOnError(crows.Scan(&colName))
				colNames = append(colNames, colName)
			}
			lib.FatalOnError(crows.Err())
			if len(colNames) == 0 {
				lib.Printf("Warning: no tag values for (%s, %s)\n", col.Column, col.Tag)
				if ch != nil {
					ch <- false
				}
				return
			}
			if ctx.Debug > 0 {
				lib.Printf("Ensure columns: %+v --> %+v\n", col, colNames)
			}
			rows := lib.QuerySQLWithErr(
				con,
				&ctx,
				fmt.Sprintf(
					"select tablename from pg_catalog.pg_tables where "+
						"schemaname = 'public' and substring(tablename from %s) is not null",
					lib.NValue(1),
				),
				col.TableRegexp,
			)
			defer func() { lib.FatalOnError(rows.Close()) }()
			table := ""
			numTables := 0
			for rows.Next() {
				lib.FatalOnError(rows.Scan(&table))
				for _, colName := range colNames {
					_, err := lib.ExecSQL(
						con,
						&ctx,
						"alter table \""+table+"\" add column \""+colName+"\" double precision not null default 0.0",
					)
					if err == nil {
						lib.Printf("Added column \"%s\" to \"%s\" table\n", colName, table)
					}
				}
				numTables++
			}
			lib.FatalOnError(rows.Err())
			if numTables == 0 {
				lib.Printf("Warning: '%+v': no table hits", col)
			}
			// Synchronize go routine
			if ch != nil {
				ch <- numTables > 0
			}
		}(ch, i)
		// go routine called with 'ch' channel to sync and column config index
		nThreads++
		if nThreads == thrN {
			<-ch
			nThreads--
		}
	}
	// Usually all work happens on '<-ch'
	lib.Printf("Final threads join\n")
	for nThreads > 0 {
		<-ch
		nThreads--
	}
}

func main() {
	dtStart := time.Now()
	ensureColumns()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
