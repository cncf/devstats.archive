package main

import (
	"io/ioutil"
	"time"

	lib "gha2db"

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
	bp := lib.IDBBatchPoints(&ctx, &ic)

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

	// Iterate tags
	for _, tag := range allTags.Tags {
		if ctx.Debug > 0 {
			lib.Printf("Tag '%s' --> '%s'\n", tag.Name, tag.SeriesName)
		}
		// Read SQL file
		bytes, err := ioutil.ReadFile(dataPrefix + "metrics/" + tag.SQLFile + ".sql")
		lib.FatalOnError(err)
		sqlQuery := string(bytes)

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
			bp.AddPoint(pt)
		}
		lib.FatalOnError(rows.Err())
	}

	// Write the batch
	if !ctx.SkipIDB {
		err := ic.Write(bp)
		lib.FatalOnError(err)
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
