package main

import (
	lib "devstats"
	"encoding/json"
	"io/ioutil"
	"os"
	"time"

	yaml "gopkg.in/yaml.v2"
)

type allProjects struct {
	Projects []project `json:"projects"`
	Summary  string    `json:"summary"`
}

type project struct {
	Name         string `json:"name"`
	Title        string `json:"title"`
	Status       string `json:"status"`
	Repo         string `json:"repo"`
	DashboardURL string `json:"dashboardUrl"`
	DBDumpURL    string `json:"dbDumpUrl"`
}

type projectStats struct {
	Totals           activityTotals `json:"activityTotals"`
	LatestVersion    string         `json:"latestVersion"`
	OpenIssues       int            `json:"openIssues"`
	RecentDiscussion int            `json:"recentDiscussion"`
	Stars            int            `json:"stars"`
	CommitGraph      commitGraph    `json:"commitGraph"`
}

type commitGraph struct {
	Day   [24][2]int `json:"day"`
	Week  [7][2]int  `json:"week"`
	Month [4][2]int  `json:"month"`
}

type activityTotals struct {
	Day   activityTotal `json:"day"`
	Week  activityTotal `json:"week"`
	Month activityTotal `json:"month"`
}

type activityTotal struct {
	Commits    int `json:"commits"`
	Discussion int `json:"discussion"`
	Stars      int `json:"stars"`
}

func generateJSONData(ctx *lib.Ctx, name string, stats *projectStats) {
	// Connect to Postgres DB
	con := lib.PgConnDB(ctx, name)
	defer func() { lib.FatalOnError(con.Close()) }()
}

func generateWebsiteData() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Get hostname
	hostname, err := os.Hostname()
	lib.FatalOnError(err)
	proto := "https://"
	prefix := proto + hostname + "/"

	// Read defined projects
	data, err := ioutil.ReadFile(dataPrefix + ctx.ProjectsYaml)
	lib.FatalOnError(err)

	var projects lib.AllProjects
	lib.FatalOnError(yaml.Unmarshal(data, &projects))

	// Get ordered & filtered projects
	var jprojs allProjects
	pstats := make(map[string]projectStats)
	names, projs := lib.GetProjectsList(&ctx, &projects)
	for i, name := range names {
		proj := projs[i]
		dashURL := proto + name + "." + hostname
		if name == "kubernetes" {
			dashURL = proto + "k8s." + hostname
		}
		jproj := project{
			Name:         name,
			Title:        proj.FullName,
			Status:       proj.Status,
			Repo:         proj.MainRepo,
			DashboardURL: dashURL,
			DBDumpURL:    prefix + proj.PDB + ".dump",
		}
		jprojs.Projects = append(jprojs.Projects, jproj)
		pstats[name] = projectStats{}
	}
	jprojs.Summary = "all"

	// Marshal JSON
	jsonBytes, err := json.Marshal(jprojs)
	lib.FatalOnError(err)
	pretty := lib.PrettyPrintJSON(jsonBytes)
	fn := ctx.JSONsDir + "projects.json"
	lib.FatalOnError(ioutil.WriteFile(fn, pretty, 0644))

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)

	if thrN > 1 {
		ch := make(chan struct{})
		nThreads := 0
		for name, stats := range pstats {
			go func(ch chan struct{}, name string, stats projectStats) {
				generateJSONData(&ctx, name, &stats)
				jsonBytes, err := json.Marshal(stats)
				lib.FatalOnError(err)
				pretty := lib.PrettyPrintJSON(jsonBytes)
				fn := ctx.JSONsDir + name + ".json"
				lib.FatalOnError(ioutil.WriteFile(fn, pretty, 0644))
				ch <- struct{}{}
			}(ch, name, stats)
			nThreads++
			if nThreads == thrN {
				<-ch
				nThreads--
			}
		}
		lib.Printf("Final threads join\n")
		for nThreads > 0 {
			<-ch
			nThreads--
		}
	} else {
		lib.Printf("Using single threaded version\n")
		for name, stats := range pstats {
			generateJSONData(&ctx, name, &stats)
			jsonBytes, err := json.Marshal(stats)
			lib.FatalOnError(err)
			pretty := lib.PrettyPrintJSON(jsonBytes)
			fn := ctx.JSONsDir + name + ".json"
			lib.FatalOnError(ioutil.WriteFile(fn, pretty, 0644))
		}
	}
}

func main() {
	dtStart := time.Now()
	generateWebsiteData()
	dtEnd := time.Now()
	lib.Printf("Generated website data in: %v\n", dtEnd.Sub(dtStart))
}
