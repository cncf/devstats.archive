package devstats

import (
	"database/sql"
	"fmt"
	"strings"
	"time"
)

// Tags contain list of TSDB tags
type Tags struct {
	Tags []Tag `yaml:"tags"`
}

// Tag contain each TSDB tag data
type Tag struct {
	Name       string            `yaml:"name"`
	SQLFile    string            `yaml:"sql"`
	SeriesName string            `yaml:"series_name"`
	NameTag    string            `yaml:"name_tag"`
	ValueTag   string            `yaml:"value_tag"`
	OtherTags  map[string]string `yaml:"other_tags"`
}

// ProcessTag - insert given Tag into Postgres TSDB
func ProcessTag(con *sql.DB, ctx *Ctx, tg *Tag, replaces [][]string) {
	// Batch TS points
	var pts TSPoints

	// Local or cron mode
	dataPrefix := DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Per project directory for SQL files
	dir := Metrics
	if ctx.Project != "" {
		dir += ctx.Project + "/"
	}

	// Read SQL file
	bytes, err := ReadFile(ctx, dataPrefix+dir+tg.SQLFile+".sql")
	FatalOnError(err)
	sqlQuery := string(bytes)

	// Handle excluding bots
	bytes, err = ReadFile(ctx, dataPrefix+"util_sql/exclude_bots.sql")
	FatalOnError(err)
	excludeBots := string(bytes)

	// Transform SQL
	sqlQuery = strings.Replace(sqlQuery, "{{lim}}", "69", -1)
	sqlQuery = strings.Replace(sqlQuery, "{{exclude_bots}}", excludeBots, -1)

	// Replaces
	for _, replace := range replaces {
		if len(replace) != 2 {
			FatalOnError(fmt.Errorf("replace(s) should have length 2, invalid: %+v", replace))
		}
		sqlQuery = strings.Replace(sqlQuery, replace[0], replace[1], -1)
	}

	// Execute SQL
	rows := QuerySQLWithErr(con, ctx, sqlQuery)
	defer func() { FatalOnError(rows.Close()) }()

	// Drop current tags
	table := "t" + tg.SeriesName
	if TableExists(con, ctx, table) {
		ExecSQLWithErr(con, ctx, "truncate "+table)
	}
	tm := TimeParseAny("2014-01-01")

	// Columns
	columns, err := rows.Columns()
	FatalOnError(err)
	colIdx := make(map[string]int)
	for i, column := range columns {
		colIdx[column] = i
	}

	// Iterate tag values
	tags := make(map[string]string)
	iVals := make([]interface{}, len(columns))
	for i := range columns {
		iVals[i] = new([]byte)
	}
	got := false
	for rows.Next() {
		got = true
		FatalOnError(rows.Scan(iVals...))
		sVals := []string{}
		for _, iVal := range iVals {
			sVal := ""
			if iVal != nil {
				sVal = string(*iVal.(*[]byte))
			}
			sVals = append(sVals, sVal)
		}
		strVal := sVals[0]
		if tg.NameTag != "" {
			tags[tg.NameTag] = strVal
		}
		if tg.ValueTag != "" {
			tags[tg.ValueTag] = NormalizeName(strVal)
		}
		if tg.OtherTags != nil {
			for tName, tValue := range tg.OtherTags {
				cIdx, ok := colIdx[tValue]
				if !ok {
					Fatalf("other tag: name: %s: column %s not found", tName, tValue)
				}
				tags[tName] = sVals[cIdx]
				tags[tName+"_norm"] = NormalizeName(sVals[cIdx])
			}
		}
		if ctx.Debug > 0 {
			Printf("'%s': %+v\n", tg.SeriesName, tags)
		}
		// Add batch point
		pt := NewTSPoint(ctx, tg.SeriesName, "", tags, nil, tm)
		AddTSPoint(ctx, &pts, pt)
		tm = tm.Add(time.Hour)
	}
	FatalOnError(rows.Err())
	if !got {
		Printf("Warning: Tag '%+v' have no values\n", &tg)
	}

	// Write the batch
	if !ctx.SkipTSDB {
		WriteTSPoints(ctx, con, &pts, "", nil)
	} else if ctx.Debug > 0 {
		Printf("Skipping tags series write\n")
	}
}
