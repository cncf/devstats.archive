package devstats

import (
	"context"
	"fmt"
	"io/ioutil"
	"regexp"
	"sort"
	"strings"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

// Annotations contain list of annotations
type Annotations struct {
	Annotations []Annotation
}

// Annotation contain each annotation data
type Annotation struct {
	Name string    `yaml:"title"`
	Date time.Time `yaml:"date"`
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

// GetAnnotations queries GitHub `orgRepo` via GitHub API (using ctx.GitHubOAuth)
// for all tags and returns those matching `annoRegexp`
func GetAnnotations(ctx *Ctx, orgRepo, annoRegexp string) (annotations Annotations) {
	// Get org and repo from orgRepo
	ary := strings.Split(orgRepo, "/")
	if len(ary) != 2 {
		FatalOnError(fmt.Errorf("main repository format must be 'org/repo', found '%s'", orgRepo))
	}
	org := ary[0]
	repo := ary[1]

	// Compile annotation regexp if present, if no regexp then return all tags
	var re *regexp.Regexp
	if annoRegexp != "" {
		re = regexp.MustCompile(annoRegexp)
	}

	// Get GitHub OAuth from env or from file
	oAuth := ctx.GitHubOAuth
	if strings.Contains(ctx.GitHubOAuth, "/") {
		bytes, err := ioutil.ReadFile(ctx.GitHubOAuth)
		FatalOnError(err)
		oAuth = strings.TrimSpace(string(bytes))
	}

	// GitHub authentication or use public access
	ghCtx := context.Background()
	var client *github.Client
	if oAuth == "-" {
		client = github.NewClient(nil)
	} else {
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: oAuth},
		)
		tc := oauth2.NewClient(ghCtx, ts)
		client = github.NewClient(tc)
	}

	// Get Tags list
	opt := &github.ListOptions{PerPage: 1000}
	//var allTags []*github.RepositoryTag
	for {
		tags, resp, err := client.Repositories.ListTags(context.Background(), org, repo, opt)
		if _, ok := err.(*github.RateLimitError); ok {
			Printf("hit rate limit on %s '%s'\n", orgRepo, annoRegexp)
		}
		FatalOnError(err)
		for _, tag := range tags {
			tagName := *tag.Name
			if re.MatchString(tagName) {
				fmt.Printf("tag: %s\n", *tag.Name)
			}
		}
		//allTags = append(allTags, tags...)
		if resp.NextPage == 0 {
			break
		}
		opt.Page = resp.NextPage
	}

	FatalOnError(fmt.Errorf("re: %+v, oauth: %+v, repo: %+v\nannotations: %+v\n", re, oAuth, orgRepo, annotations))
	return
}

// ProcessAnnotations Creates IfluxDB annotations and quick_series
func ProcessAnnotations(ctx *Ctx, annotations *Annotations, dt time.Time) {
	// Connect to InfluxDB
	ic := IDBConn(ctx)
	defer ic.Close()

	// Get BatchPoints
	var pts IDBBatchPointsN
	bp := IDBBatchPoints(ctx, &ic)
	pts.NPoints = 0
	pts.Points = &bp

	// Iterate annotations
	for _, annotation := range annotations.Annotations {
		if !annotation.Date.After(dt) {
			continue
		}
		fields := map[string]interface{}{
			"title":       annotation.Name,
			"description": annotation.Name,
		}
		// Add batch point
		if ctx.Debug > 0 {
			Printf(
				"Series: %v: Date: %v: '%v', '%v'\n",
				"annotations",
				ToYMDDate(annotation.Date),
				annotation.Name,
				annotation.Name,
			)
		}
		pt := IDBNewPointWithErr("annotations", nil, fields, annotation.Date)
		IDBAddPointN(ctx, &ic, &pts, pt)
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
			Printf(
				"Series: %v: %+v\n",
				tagName,
				tags,
			)
		}
		// Add batch point
		pt := IDBNewPointWithErr(tagName, tags, fields, tm)
		IDBAddPointN(ctx, &ic, &pts, pt)
		tm = tm.Add(time.Hour)
	}

	// Annotations must be sorted to create quick ranges
	sort.Sort(AnnotationsByDate(annotations.Annotations))

	// Add '(i) - (i+1)' annotation ranges
	lastIndex := len(annotations.Annotations) - 1
	for index, annotation := range annotations.Annotations {
		if !annotation.Date.After(dt) {
			continue
		}
		if index == lastIndex {
			sfx := fmt.Sprintf("anno_%d_now", index)
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
			pt := IDBNewPointWithErr(tagName, tags, fields, tm)
			IDBAddPointN(ctx, &ic, &pts, pt)
			tm = tm.Add(time.Hour)
			break
		}
		nextAnnotation := annotations.Annotations[index+1]
		sfx := fmt.Sprintf("anno_%d_%d", index, index+1)
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
		pt := IDBNewPointWithErr(tagName, tags, fields, tm)
		IDBAddPointN(ctx, &ic, &pts, pt)
		tm = tm.Add(time.Hour)
	}

	// Write the batch
	if !ctx.SkipIDB {
		FatalOnError(IDBWritePointsN(ctx, &ic, &pts))
	} else if ctx.Debug > 0 {
		Printf("Skipping annotations series write\n")
	}
}
