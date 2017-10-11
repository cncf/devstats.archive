package main

import (
	"io/ioutil"
	"os"
	"time"

	lib "gha2db"

	yaml "gopkg.in/yaml.v2"
)

// annotations contain list of annotations
type annotations struct {
	Annotations []annotation `yaml:"annotations"`
}

// annotation contain each annotation data
type annotation struct {
	Title       string    `yaml:"title"`
	Description string    `yaml:"description"`
	SeriesName  string    `yaml:"series_name"`
	Date        time.Time `yaml:"date"`
}

// makeAnnotations: Insert InfluxDB annotations starting after `dt`
func makeAnnotations(sdt string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Parse input dates
	dt := lib.TimeParseAny(sdt)

	// Connect to InfluxDB
	ic := lib.IDBConn(&ctx)
	defer ic.Close()

	// Get BatchPoints
	bp := lib.IDBBatchPoints(&ctx, &ic)

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
	var annotations annotations
	lib.FatalOnError(yaml.Unmarshal(data, &annotations))

	// Iterate annotations
	for _, annotation := range annotations.Annotations {
		if !annotation.Date.After(dt) {
			continue
		}
		fields := map[string]interface{}{
			"title":       annotation.Title,
			"description": annotation.Description,
		}
		// Add batch point
		if ctx.Debug > 0 {
			lib.Printf(
				"Series: %v: Date: %v: '%v', '%v'\n",
				annotation.SeriesName,
				lib.ToYMDDate(annotation.Date),
				annotation.Title,
				annotation.Description,
			)
		}
		pt := lib.IDBNewPointWithErr(annotation.SeriesName, nil, fields, annotation.Date)
		bp.AddPoint(pt)
	}

	// Write the batch
	if !ctx.SkipIDB {
		err := ic.Write(bp)
		lib.FatalOnError(err)
	} else if ctx.Debug > 0 {
		lib.Printf("Skipping annotations series write\n")
	}
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
