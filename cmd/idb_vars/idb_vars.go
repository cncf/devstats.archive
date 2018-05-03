package main

import (
	"os/exec"
	"strings"
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
	Tag     string   `yaml:"tag"`
	Name    string   `yaml:"name"`
	Value   string   `yaml:"value"`
	Command []string `yaml:"command"`
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
	data, err := lib.ReadFile(&ctx, dataPrefix+ctx.IVarsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	var allVars vars
	lib.FatalOnError(yaml.Unmarshal(data, &allVars))

	// No fields value needed
	fields := map[string]interface{}{"value": 0.0}

	// Iterate vars
	for _, tag := range allVars.Vars {
		if ctx.Debug > 0 {
			lib.Printf("Tag '%s', Name '%s', Value '%s', Command %v\n", tag.Tag, tag.Name, tag.Value, tag.Command)
		}
		if tag.Tag == "" || tag.Name == "" || (tag.Value == "" && len(tag.Command) == 0) {
			lib.Printf("Incorrect variable configuration, skipping\n")
			continue
		}
		// Drop current vars
		lib.QueryIDB(ic, &ctx, "drop series from \""+tag.Tag+"\"")

		if len(tag.Command) > 0 {
			for i := range tag.Command {
				tag.Command[i] = strings.Replace(tag.Command[i], "{{datadir}}", dataPrefix, -1)
			}
			cmdBytes, err := exec.Command(tag.Command[0], tag.Command[1:]...).CombinedOutput()
			if err != nil {
				lib.Printf("Failed command: %s %v\n", tag.Command[0], tag.Command[1:])
				lib.FatalOnError(err)
				return
			}
			outString := strings.TrimSpace(string(cmdBytes))
			if outString != "" {
				tag.Value = outString
				if ctx.Debug > 0 {
					lib.Printf("Tag '%s', Name '%s', New Value '%s'\n", tag.Tag, tag.Name, tag.Value)
				}
			}
		}

		// Insert tag name/value
		lib.IDBAddPointN(
			&ctx,
			&ic,
			&pts,
			lib.IDBNewPointWithErr(
				&ctx,
				tag.Tag,
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
