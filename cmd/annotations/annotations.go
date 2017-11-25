package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"sort"
	"time"

	lib "devstats"

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

// annotations Sort interface
type annotationsByDate []annotation

func (a annotationsByDate) Len() int {
	return len(a)
}
func (a annotationsByDate) Swap(i, j int) {
	a[i], a[j] = a[j], a[i]
}
func (a annotationsByDate) Less(i, j int) bool {
	return a[i].Date.Before(a[j].Date)
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

	// Special ranges
	periods := [][3]string{
		{"d", "Last day", "1 day"},
		{"w", "Last week", "1 week"},
		{"d10", "Last 10 days", "10 days"},
		{"m", "Last month", "1 month"},
		{"q", "Last quarter", "3 months"},
		{"y", "Last year", "1 year"},
		{"y10", "Last decade", "10 years"},
	}

	// tags:
	// suffix: will be used as InfluxDB series name suffix and Grafana drop-down value (non-dsplayed)
	// name: will be used as Grafana drop-down value name
	// data: is suffix;period;from;to
	// period: only for special values listed here, last ... week, day, quarter, devade etc - will be passed to Postgres
	// from: only filled when using annotations range - exact date from
	// to: only filled when using annotations range - exact date to
	tags := make(map[string]string)
	// No fields value needed
	fields := map[string]interface{}{"value": 0.0}

	// Add special periods
	tagName := "quick_ranges"
	tm := time.Now()

	// Last "..." periods
	for _, period := range periods {
		tags[tagName+"_suffix"] = period[0]
		tags[tagName+"_name"] = period[1]
		tags[tagName+"_data"] = period[0] + ";" + period[2] + ";;"
		if ctx.Debug > 0 {
			lib.Printf(
				"Series: %v: %+v\n",
				tagName,
				tags,
			)
		}
		// Add batch point
		pt := lib.IDBNewPointWithErr(tagName, tags, fields, tm)
		bp.AddPoint(pt)
		tm = tm.Add(time.Hour)
	}

	// Annotations must be sorted to create ranes
	sort.Sort(annotationsByDate(annotations.Annotations))

	// Add '(i) - (i+1)' annotation ranges
	lastIndex := len(annotations.Annotations) - 1
	for index, annotation := range annotations.Annotations {
		if !annotation.Date.After(dt) {
			continue
		}
		if index == lastIndex {
			sfx := fmt.Sprintf("anno_%d_now", index)
			tags[tagName+"_suffix"] = sfx
			tags[tagName+"_name"] = fmt.Sprintf("%s - now", annotation.Title)
			tags[tagName+"_data"] = fmt.Sprintf("%s;;%s;%s", sfx, lib.ToYMDHMSDate(annotation.Date), lib.ToYMDHMSDate(lib.NextDayStart(time.Now())))
			if ctx.Debug > 0 {
				lib.Printf(
					"Series: %v: %+v\n",
					tagName,
					tags,
				)
			}
			// Add batch point
			pt := lib.IDBNewPointWithErr(tagName, tags, fields, tm)
			bp.AddPoint(pt)
			tm = tm.Add(time.Hour)
			break
		}
		nextAnnotation := annotations.Annotations[index+1]
		sfx := fmt.Sprintf("anno_%d_%d", index, index+1)
		tags[tagName+"_suffix"] = sfx
		tags[tagName+"_name"] = fmt.Sprintf("%s - %s", annotation.Title, nextAnnotation.Title)
		tags[tagName+"_data"] = fmt.Sprintf("%s;;%s;%s", sfx, lib.ToYMDHMSDate(annotation.Date), lib.ToYMDHMSDate(nextAnnotation.Date))
		if ctx.Debug > 0 {
			lib.Printf(
				"Series: %v: %+v\n",
				tagName,
				tags,
			)
		}
		// Add batch point
		pt := lib.IDBNewPointWithErr(tagName, tags, fields, tm)
		bp.AddPoint(pt)
		tm = tm.Add(time.Hour)
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
