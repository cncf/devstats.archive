package main

import (
	lib "devstats"
	"time"

	yaml "gopkg.in/yaml.v2"
)

// makeAnnotations: Insert TSDB annotations starting after `dt`
func makeAnnotations() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Needs GHA2DB_PROJECT variable set
	if ctx.Project == "" {
		lib.Fatalf("you have to set project via GHA2DB_PROJECT environment variable")
	}

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read defined projects
	data, err := lib.ReadFile(&ctx, dataPrefix+ctx.ProjectsYaml)
	lib.FatalOnError(err)
	var projects lib.AllProjects
	lib.FatalOnError(yaml.Unmarshal(data, &projects))

	// Get current project's main repo and annotation regexp
	proj, ok := projects.Projects[ctx.Project]
	if !ok {
		lib.Fatalf("project '%s' not found in '%s'", ctx.Project, ctx.ProjectsYaml)
	}
	ctx.SharedDB = proj.SharedDB
	ctx.ProjectMainRepo = proj.MainRepo

	// Get annotations using GitHub API and add annotations and quick ranges to TSDB
	if proj.MainRepo != "" {
		annotations := lib.GetAnnotations(&ctx, proj.MainRepo, proj.AnnotationRegexp)
		lib.ProcessAnnotations(&ctx, &annotations, proj.StartDate, proj.JoinDate)
	} else if proj.StartDate != nil && proj.JoinDate != nil {
		annotations := lib.GetFakeAnnotations(*proj.StartDate, *proj.JoinDate)
		lib.ProcessAnnotations(&ctx, &annotations, nil, nil)
	}
}

func main() {
	dtStart := time.Now()
	makeAnnotations()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
