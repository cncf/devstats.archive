package main

import (
	lib "devstats"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"time"

	yaml "gopkg.in/yaml.v2"
)

/*
type AllProjects struct {
	Projects map[string]Project `yaml:"projects"`
}

// Project contain mapping from project name to its command line used to sync it
type Project struct {
	CommandLine      []string          `yaml:"command_line"`
	StartDate        *time.Time        `yaml:"start_date"`
	PDB              string            `yaml:"psql_db"`
	Disabled         bool              `yaml:"disabled"`
	MainRepo         string            `yaml:"main_repo"`
	AnnotationRegexp string            `yaml:"annotation_regexp"`
	Order            int               `yaml:"order"`
	JoinDate         *time.Time        `yaml:"join_date"`
	FilesSkipPattern string            `yaml:"files_skip_pattern"`
	Env              map[string]string `yaml:"env"`
}
*/

type allProjects struct {
	Projects []project `json:"projects"`
}

type project struct {
	Title string `json:"title"`
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
		jproj := project{
			Title: name,
		}
		jprojs.Projects = append(jprojs.Projects, jproj)
		fmt.Printf("%s: %v\n", name, proj)
	}

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
