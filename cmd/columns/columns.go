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
	dataPrefix := ctx.DataDir
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
	ch := make(chan [2][]string)
	nThreads := 0
	allTables := []string{}
	allCols := []string{}
	// Use integer index to pass to go rountine
	for i := range allColumns.Columns {
		go func(ch chan [2][]string, idx int) {
			tables := []string{}
			cols := []string{}
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
					ch <- [2][]string{tables, cols}
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
						"alter table \""+table+"\" add column \""+colName+"\" double precision",
					)
					if err == nil {
						lib.Printf("Added column \"%s\" to \"%s\" table\n", colName, table)
						tables = append(tables, table)
						cols = append(cols, colName)
						//} else {
						//	lib.Printf("%+v\n", err)
					}
				}
				numTables++
			}
			lib.FatalOnError(rows.Err())
			if numTables == 0 {
				lib.Printf("Warning: '%+v': no table hits\n", col)
			}
			// Synchronize go routine
			if ch != nil {
				ch <- [2][]string{tables, cols}
			}
		}(ch, i)
		// go routine called with 'ch' channel to sync and column config index
		nThreads++
		if nThreads == thrN {
			data := <-ch
			tables := data[0]
			cols := data[1]
			for i, table := range tables {
				col := cols[i]
				allTables = append(allTables, table)
				allCols = append(allCols, col)
			}
			nThreads--
		}
	}
	// Usually all work happens on '<-ch'
	for nThreads > 0 {
		data := <-ch
		tables := data[0]
		cols := data[1]
		for i, table := range tables {
			col := cols[i]
			allTables = append(allTables, table)
			allCols = append(allCols, col)
		}
		nThreads--
	}
	//lib.Printf("Tables: %+v\n", allTables)
	//lib.Printf("Columns: %+v\n", allCols)
	cfg := make(map[string]map[string]struct{})
	for i, table := range allTables {
		col := allCols[i]
		_, ok := cfg[table]
		if !ok {
			cfg[table] = make(map[string]struct{})
		}
		cfg[table][col] = struct{}{}
	}
	if ctx.Debug > 0 {
		lib.Printf("Cfg: %+v\n", cfg)
	}

	// process separate tables in parallel
	sch := make(chan [2]string)
	nThreads = 0
	for table, columns := range cfg {
		go func(sch chan [2]string, tab string, cols map[string]struct{}) {
			s := "update \"" + tab + "\" set "
			for col := range cols {
				s += "\"" + col + "\" = 0.0, "
			}
			s = s[:len(s)-2]
			dtStart := time.Now()
			lib.ExecSQLWithErr(con, &ctx, s)
			dtEnd := time.Now()
			lib.Printf("Mass updated \"%s\", took: %v\n", tab, dtEnd.Sub(dtStart))
			s = "alter table \"" + tab + "\" "
			for col := range cols {
				s += "alter column \"" + col + "\" set not null, alter column \"" + col + "\" set default 0.0, "
			}
			s = s[:len(s)-2]
			dtStart = time.Now()
			lib.ExecSQLWithErr(con, &ctx, s)
			dtEnd = time.Now()
			lib.Printf("Altered \"%s\" defaults and restrictions, took: %v\n", tab, dtEnd.Sub(dtStart))
			if sch != nil {
				sch <- [2]string{tab, "ok"}
			}
		}(sch, table, columns)
		nThreads++
		if nThreads == thrN {
			<-sch
			nThreads--
		}
	}
	for nThreads > 0 {
		<-sch
		nThreads--
	}
}

func main() {
	dtStart := time.Now()
	ensureColumns()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
