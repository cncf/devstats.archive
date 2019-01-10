package devstats

import (
	"fmt"
	"regexp"
	"sort"
	"strconv"
	"strings"
	"time"
)

// Annotations contain list of annotations
type Annotations struct {
	Annotations []Annotation
}

// Annotation contain each annotation data
type Annotation struct {
	Name        string
	Description string
	Date        time.Time
}

// AnnotationsByDate annotations Sort interface
type AnnotationsByDate []Annotation

func (a AnnotationsByDate) Len() int {
	return len(a)
}
func (a AnnotationsByDate) Swap(i, j int) {
	a[i], a[j] = a[j], a[i]
}
func (a AnnotationsByDate) Less(i, j int) bool {
	return a[i].Date.Before(a[j].Date)
}

// GetFakeAnnotations - returns 'startDate - joinDate' and 'joinDate - now' annotations
func GetFakeAnnotations(startDate, joinDate time.Time) (annotations Annotations) {
	minDate := TimeParseAny("2014-01-01")
	if joinDate.Before(minDate) || startDate.Before(minDate) || !joinDate.After(startDate) {
		return
	}
	annotations.Annotations = append(
		annotations.Annotations,
		Annotation{
			Name:        "Project start",
			Description: ToYMDDate(startDate) + " - project starts",
			Date:        startDate,
		},
	)
	annotations.Annotations = append(
		annotations.Annotations,
		Annotation{
			Name:        "First CNCF project join date",
			Description: ToYMDDate(joinDate),
			Date:        joinDate,
		},
	)
	return
}

// GetAnnotations queries uses `git` to get `orgRepo` all tags list
// for all tags and returns those matching `annoRegexp`
func GetAnnotations(ctx *Ctx, orgRepo, annoRegexp string) (annotations Annotations) {
	// Get org and repo from orgRepo
	ary := strings.Split(orgRepo, "/")
	if len(ary) != 2 {
		Fatalf("main repository format must be 'org/repo', found '%s'", orgRepo)
	}

	// Compile annotation regexp if present, if no regexp then return all tags
	var re *regexp.Regexp
	if annoRegexp != "" {
		re = regexp.MustCompile(annoRegexp)
	}

	// Local or cron mode?
	cmdPrefix := ""
	if ctx.Local {
		cmdPrefix = LocalGitScripts
	}

	// We need this to capture 'git_tags.sh' output.
	ctx.ExecOutput = true

	// Get tags is using shell script that does 'chdir'
	// We cannot chdir because this is a multithreaded app
	// And all threads share CWD (current working directory)
	if ctx.Debug > 0 {
		Printf("Getting tags for repo %s\n", orgRepo)
	}
	dtStart := time.Now()
	rwd := ctx.ReposDir + orgRepo
	tagsStr, err := ExecCommand(
		ctx,
		[]string{cmdPrefix + "git_tags.sh", rwd},
		map[string]string{"GIT_TERMINAL_PROMPT": "0"},
	)
	dtEnd := time.Now()
	FatalOnError(err)

	tags := strings.Split(tagsStr, "\n")
	nTags := 0

	minDate := TimeParseAny("2014-01-01")
	for _, tagData := range tags {
		data := strings.TrimSpace(tagData)
		if data == "" {
			continue
		}
		// Use '♂♀' separator to avoid any character that can appear inside tag name or description
		tagDataAry := strings.Split(data, "♂♀")
		if len(tagDataAry) != 3 {
			Fatalf("invalid tagData returned for repo: %s: '%s'", orgRepo, data)
		}
		tagName := tagDataAry[0]
		if re != nil && !re.MatchString(tagName) {
			continue
		}
		if tagDataAry[1] == "" {
			if ctx.Debug > 0 {
				Printf("Empty time returned for repo: %s, tag: %s\n", orgRepo, tagName)
			}
			continue
		}
		unixTimeStamp, err := strconv.ParseInt(tagDataAry[1], 10, 64)
		if err != nil {
			Printf("Invalid time returned for repo: %s, tag: %s: '%s'\n", orgRepo, tagName, data)
		}
		FatalOnError(err)
		creatorDate := time.Unix(unixTimeStamp, 0)
		if creatorDate.Before(minDate) {
			if ctx.Debug > 0 {
				Printf("Skipping annotation %v because it is before %v\n", creatorDate, minDate)
			}
			continue
		}
		message := tagDataAry[2]
		if len(message) > 40 {
			message = message[0:40]
		}
		replacer := strings.NewReplacer("\n", " ", "\r", " ", "\t", " ")
		message = replacer.Replace(message)

		annotations.Annotations = append(
			annotations.Annotations,
			Annotation{
				Name:        tagName,
				Description: message,
				Date:        creatorDate,
			},
		)
		nTags++
	}

	if ctx.Debug > 0 {
		Printf("Got %d tags for %s, took %v\n", nTags, orgRepo, dtEnd.Sub(dtStart))
	}

	return
}

// ProcessAnnotations Creates IfluxDB annotations and quick_series
func ProcessAnnotations(ctx *Ctx, annotations *Annotations, startDate, joinDate *time.Time) {
	// Connect to Postgres
	ic := PgConn(ctx)
	defer func() { FatalOnError(ic.Close()) }()

	// Optional ElasticSearch output
	var es *ES
	if ctx.UseES {
		es = ESConn(ctx, "d_")
	}

	// Get BatchPoints
	var pts TSPoints

	// Annotations must be sorted to create quick ranges
	sort.Sort(AnnotationsByDate(annotations.Annotations))

	// Iterate annotations
	for _, annotation := range annotations.Annotations {
		fields := map[string]interface{}{
			"title":       annotation.Name,
			"description": annotation.Description,
		}
		// Add batch point
		if ctx.Debug > 0 {
			Printf(
				"Series: %v: Date: %v: '%v', '%v'\n",
				"annotations",
				ToYMDDate(annotation.Date),
				annotation.Name,
				annotation.Description,
			)
		}
		pt := NewTSPoint(ctx, "annotations", "", nil, fields, annotation.Date, false)
		AddTSPoint(ctx, &pts, pt)
	}

	// If both start and join dates are present then join date must be after start date
	if startDate == nil || joinDate == nil || (startDate != nil && joinDate != nil && joinDate.After(*startDate)) {
		// Project start date (additional annotation not used in quick ranges)
		if startDate != nil {
			fields := map[string]interface{}{
				"title":       "Project start date",
				"description": ToYMDDate(*startDate) + " - project starts",
			}
			// Add batch point
			if ctx.Debug > 0 {
				Printf(
					"Project start date: %v: '%v', '%v'\n",
					ToYMDDate(*startDate),
					fields["title"],
					fields["description"],
				)
			}
			pt := NewTSPoint(ctx, "annotations", "", nil, fields, *startDate, false)
			AddTSPoint(ctx, &pts, pt)
		}

		// Join CNCF (additional annotation not used in quick ranges)
		if joinDate != nil {
			fields := map[string]interface{}{
				"title":       "CNCF join date",
				"description": ToYMDDate(*joinDate) + " - joined CNCF",
			}
			// Add batch point
			if ctx.Debug > 0 {
				Printf(
					"CNCF join date: %v: '%v', '%v'\n",
					ToYMDDate(*joinDate),
					fields["title"],
					fields["description"],
				)
			}
			pt := NewTSPoint(ctx, "annotations", "", nil, fields, *joinDate, false)
			AddTSPoint(ctx, &pts, pt)
		}
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
	// suffix: will be used as TS series name suffix and Grafana drop-down value (non-dsplayed)
	// name: will be used as Grafana drop-down value name
	// data: is suffix;period;from;to
	// period: only for special values listed here, last ... week, day, quarter, devade etc - will be passed to Postgres
	// from: only filled when using annotations range - exact date from
	// to: only filled when using annotations range - exact date to
	tags := make(map[string]string)

	// Add special periods
	tagName := "quick_ranges"
	tm := TimeParseAny("2014-01-01")

	// Last "..." periods
	for _, period := range periods {
		tags[tagName+"_suffix"] = period[0]
		tags[tagName+"_name"] = period[1]
		tags[tagName+"_data"] = period[0] + ";" + period[2] + ";;"
		if ctx.Debug > 0 {
			Printf(
				"Series: %v: %+v\n",
				tagName,
				tags,
			)
		}
		// Add batch point
		pt := NewTSPoint(ctx, tagName, "", tags, nil, tm, false)
		AddTSPoint(ctx, &pts, pt)
		tm = tm.Add(time.Hour)
	}

	// Add '(i) - (i+1)' annotation ranges
	lastIndex := len(annotations.Annotations) - 1
	for index, annotation := range annotations.Annotations {
		if index == lastIndex {
			sfx := fmt.Sprintf("a_%d_n", index)
			tags[tagName+"_suffix"] = sfx
			tags[tagName+"_name"] = fmt.Sprintf("%s - now", annotation.Name)
			tags[tagName+"_data"] = fmt.Sprintf("%s;;%s;%s", sfx, ToYMDHMSDate(annotation.Date), ToYMDHMSDate(NextDayStart(time.Now())))
			if ctx.Debug > 0 {
				Printf(
					"Series: %v: %+v\n",
					tagName,
					tags,
				)
			}
			// Add batch point
			pt := NewTSPoint(ctx, tagName, "", tags, nil, tm, false)
			AddTSPoint(ctx, &pts, pt)
			tm = tm.Add(time.Hour)
			break
		}
		nextAnnotation := annotations.Annotations[index+1]
		sfx := fmt.Sprintf("a_%d_%d", index, index+1)
		tags[tagName+"_suffix"] = sfx
		tags[tagName+"_name"] = fmt.Sprintf("%s - %s", annotation.Name, nextAnnotation.Name)
		tags[tagName+"_data"] = fmt.Sprintf("%s;;%s;%s", sfx, ToYMDHMSDate(annotation.Date), ToYMDHMSDate(nextAnnotation.Date))
		if ctx.Debug > 0 {
			Printf(
				"Series: %v: %+v\n",
				tagName,
				tags,
			)
		}
		// Add batch point
		pt := NewTSPoint(ctx, tagName, "", tags, nil, tm, false)
		AddTSPoint(ctx, &pts, pt)
		tm = tm.Add(time.Hour)
	}

	// 2 special periods: before and after joining CNCF
	if startDate != nil && joinDate != nil && joinDate.After(*startDate) {
		// From project start to CNCF join date
		sfx := "c_b"
		tags[tagName+"_suffix"] = sfx
		tags[tagName+"_name"] = "Before joining CNCF"
		tags[tagName+"_data"] = fmt.Sprintf("%s;;%s;%s", sfx, ToYMDHMSDate(*startDate), ToYMDHMSDate(*joinDate))
		if ctx.Debug > 0 {
			Printf(
				"Series: %v: %+v\n",
				tagName,
				tags,
			)
		}
		// Add batch point
		pt := NewTSPoint(ctx, tagName, "", tags, nil, tm, false)
		AddTSPoint(ctx, &pts, pt)
		tm = tm.Add(time.Hour)

		// From CNCF join date till now
		sfx = "c_n"
		tags[tagName+"_suffix"] = sfx
		tags[tagName+"_name"] = "Since joining CNCF"
		tags[tagName+"_data"] = fmt.Sprintf("%s;;%s;%s", sfx, ToYMDHMSDate(*joinDate), ToYMDHMSDate(NextDayStart(time.Now())))
		if ctx.Debug > 0 {
			Printf(
				"Series: %v: %+v\n",
				tagName,
				tags,
			)
		}
		// Add batch point
		pt = NewTSPoint(ctx, tagName, "", tags, nil, tm, false)
		AddTSPoint(ctx, &pts, pt)
		tm = tm.Add(time.Hour)
	}

	// Output to ElasticSearch
	if ctx.UseES {
		if es.IndexExists(ctx) {
			es.DeleteByWildcardQuery(ctx, "quick_ranges_suffix", "*_n")
		}
		es.WriteESPoints(ctx, &pts, "", [3]bool{true, false, false})
	}

	// Write the batch
	if !ctx.SkipTSDB && !ctx.UseESOnly {
		table := "tquick_ranges"
		column := "quick_ranges_suffix"
		if TableExists(ic, ctx, table) && TableColumnExists(ic, ctx, table, column) {
			ExecSQLWithErr(ic, ctx, fmt.Sprintf("delete from \"%s\" where \"%s\" like '%%_n'", table, column))
		}
		WriteTSPoints(ctx, ic, &pts, "", nil)
		// Annotations from all projects into 'allprj' database
		if !ctx.SkipSharedDB && ctx.SharedDB != "" {
			var anots TSPoints
			for _, pt := range pts {
				if pt.name != "annotations" {
					continue
				}
				pt.name = "annotations_shared"
				if pt.fields != nil {
					pt.period = ctx.Project
					pt.fields["repo"] = ctx.ProjectMainRepo
				}
				anots = append(anots, pt)
			}
			ics := PgConnDB(ctx, ctx.SharedDB)
			defer func() { FatalOnError(ics.Close()) }()
			WriteTSPoints(ctx, ics, &anots, "", nil)
		}
	} else if ctx.Debug > 0 {
		Printf("Skipping annotations series write\n")
	}
}
