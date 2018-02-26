package main

import (
	"io/ioutil"
	"os"
	"time"

	lib "devstats"

	yaml "gopkg.in/yaml.v2"
)

// vars contain list of InfluxDB tag/value pairs
type vars struct {
	Vars []tag `yaml:"vars"`
}

// tag contain each InfluxDB tag data
type tag struct {
	Name  string `yaml:"name"`
	Value string `yaml:"value"`
}

// Insert InfluxDB vars
func idbVars() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Connect to InfluxDB
	ic := lib.IDBConn(&ctx)
	defer func() { lib.FatalOnError(ic.Close()) }()

	// Get BatchPoints
	var pts lib.IDBBatchPointsN
	bp := lib.IDBBatchPoints(&ctx, &ic)
	pts.NPoints = 0
	pts.Points = &bp

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read vars to generate
	data, err := ioutil.ReadFile(dataPrefix + ctx.VarsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	var allVars vars
	lib.FatalOnError(yaml.Unmarshal(data, &allVars))

	// No fields value needed
	fields := map[string]interface{}{"value": 0.0}

	// Add hostname
	hostname, err := os.Hostname()
	if err != nil {
		hostname = ctx.DefaultHostname
	}
	lib.IDBAddPointN(
		&ctx,
		&ic,
		&pts,
		lib.IDBNewPointWithErr(
			"os",
			map[string]string{"os_hostname": hostname},
			fields,
			lib.TimeParseAny("2014"),
		),
	)

	// Iterate vars
	for _, tag := range allVars.Vars {
		if ctx.Debug > 0 {
			lib.Printf("Name '%s' --> Value '%s'\n", tag.Name, tag.Value)
		}
		// Drop current vars
		//lib.QueryIDB(ic, &ctx, "drop series from "+tag.SeriesName)

		// Insert tag name/value
		lib.IDBAddPointN(
			&ctx,
			&ic,
			&pts,
			lib.IDBNewPointWithErr(
				"vars",
				map[string]string{tag.Name: tag.Value},
				fields,
				lib.TimeParseAny("2014"),
			),
		)
	}

	// Write the batch
	if !ctx.SkipIDB {
		lib.FatalOnError(lib.IDBWritePointsN(&ctx, &ic, &pts))
	} else if ctx.Debug > 0 {
		lib.Printf("Skipping vars series write\n")
	}
}

func main() {
	dtStart := time.Now()
	idbVars()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
