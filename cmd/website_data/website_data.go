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
	}
	jprojs.Summary = "all"

	// Marshal JSON
	jsonBytes, err := json.Marshal(jprojs)
	lib.FatalOnError(err)
	pretty := lib.PrettyPrintJSON(jsonBytes)
	fn := ctx.JSONsDir + "projects.json"
	lib.FatalOnError(ioutil.WriteFile(fn, pretty, 0644))
}

func main() {
	dtStart := time.Now()
	generateWebsiteData()
	dtEnd := time.Now()
	lib.Printf("Generated website data in: %v\n", dtEnd.Sub(dtStart))
}
