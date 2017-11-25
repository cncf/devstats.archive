package main

import (
	"io/ioutil"
	"os"
	"time"

	lib "devstats"

	yaml "gopkg.in/yaml.v2"
)

// makeAnnotations: Insert InfluxDB annotations starting after `dt`
func makeAnnotations(sdt string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Parse input dates
	dt := lib.TimeParseAny(sdt)

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read annotations
	data, err := ioutil.ReadFile(dataPrefix + ctx.AnnotationsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	var annotations lib.Annotations
	lib.FatalOnError(yaml.Unmarshal(data, &annotations))

	lib.ProcessAnnotations(&ctx, &annotations, dt)
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 2 {
		lib.Printf("Required date_from\n")
		os.Exit(1)
	}
	makeAnnotations(os.Args[1])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
