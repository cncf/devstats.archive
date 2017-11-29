package main

import (
	"io/ioutil"
	"strings"
	"time"

	lib "devstats"

	yaml "gopkg.in/yaml.v2"
)

// tags contain list of InfluxDB tags
type tags struct {
	Tags []tag `yaml:"tags"`
}

// tag contain each InfluxDB tag data
type tag struct {
	Name       string `yaml:"name"`
	SQLFile    string `yaml:"sql"`
	SeriesName string `yaml:"series_name"`
	NameTag    string `yaml:"name_tag"`
	ValueTag   string `yaml:"value_tag"`
}

// Insert InfluxDB tags
func idbTags() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Connect to Postgres DB
	con := lib.PgConn(&ctx)
	defer con.Close()

	// Connect to InfluxDB
	ic := lib.IDBConn(&ctx)
	defer ic.Close()

	// Get BatchPoints
	var pts lib.IDBBatchPointsN
	bp := lib.IDBBatchPoints(&ctx, &ic)
	pts.NPoints = 0
	pts.Points = &bp

	// Local or cron mode?
	dataPrefix := "/etc/gha2db/"
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read tags to generate
	data, err := ioutil.ReadFile(dataPrefix + ctx.TagsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	var allTags tags
	lib.FatalOnError(yaml.Unmarshal(data, &allTags))

	// No fields value needed
	fields := map[string]interface{}{"value": 0.0}
	// String value to read tags into
	strVal := ""

	// Per project directory for SQL files
	dir := "metrics/"
	if ctx.Project != "" {
		dir += ctx.Project + "/"
	}

	// Iterate tags
	for _, tag := range allTags.Tags {
		if ctx.Debug > 0 {
			lib.Printf("Tag '%s' --> '%s'\n", tag.Name, tag.SeriesName)
		}
		// Read SQL file
		bytes, err := ioutil.ReadFile(dataPrefix + dir + tag.SQLFile + ".sql")
		lib.FatalOnError(err)
		sqlQuery := string(bytes)

		// Transform SQL (hardcoded limit 25 for template dropdowns
		// When dropdown contains "All" there are 26 items then, Grafana names series 1-26 --> "a"-"z"
		// Next series have no name
		sqlQuery = strings.Replace(sqlQuery, "{{lim}}", "25", -1)

		// Execute SQL
		rows := lib.QuerySQLWithErr(con, &ctx, sqlQuery)
		defer rows.Close()

		// Drop current tags
		lib.SafeQueryIDB(ic, &ctx, "drop series from "+tag.SeriesName)

		// Iterate tag values
		tags := make(map[string]string)
		for rows.Next() {
			lib.FatalOnError(rows.Scan(&strVal))
			if ctx.Debug > 0 {
				lib.Printf("'%s': %v\n", tag.SeriesName, strVal)
			}
			if tag.NameTag != "" {
				tags[tag.NameTag] = strVal
			}
			if tag.ValueTag != "" {
				tags[tag.ValueTag] = lib.NormalizeName(strVal)
			}
			// Add batch point
			pt := lib.IDBNewPointWithErr(tag.SeriesName, tags, fields, time.Now())
			lib.IDBAddPointN(&ctx, &ic, &pts, pt)
		}
		lib.FatalOnError(rows.Err())
	}

	// Write the batch
	if !ctx.SkipIDB {
		lib.FatalOnError(lib.IDBWritePointsN(&ctx, &ic, &pts))
	} else if ctx.Debug > 0 {
		lib.Printf("Skipping tags series write\n")
	}
}

func main() {
	dtStart := time.Now()
	idbTags()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
