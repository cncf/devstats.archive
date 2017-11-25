package main

import (
	lib "devstats"
	"io/ioutil"
	"time"

	yaml "gopkg.in/yaml.v2"
)

// Sync all projects from "projects.yaml", calling `gha2db_sync` for all of them
func syncAllProjects() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Set non-fatal exec mode, we want to run sync for next project(s) if current fails
	ctx.ExecFatal = false

	// Local or cron mode?
	cmdPrefix := ""
	dataPrefix := lib.DataDir
	if ctx.Local {
		cmdPrefix = "./"
		dataPrefix = "./"
	}

	// Read defined projects
	data, err := ioutil.ReadFile(dataPrefix + "projects.yaml")
	lib.FatalOnError(err)

	var projs lib.Projects
	lib.FatalOnError(yaml.Unmarshal(data, &projs))
	for _, proj := range projs.Projects {
		if proj.Disabled {
			continue
		}
		lib.Printf("Syncing %s\n", proj.Name)
		res := lib.ExecCommand(
			&ctx,
			[]string{
				cmdPrefix + "gha2db_sync",
			},
			map[string]string{
				"GHA2DB_PROJECT": proj.Name,
				"PG_DB":          proj.PDB,
				"IDB_DB":         proj.IDB,
			},
		)
		if res != nil {
			lib.Printf("Error result for %s: %+v\n", proj.Name, res)
			continue
		}
		lib.Printf("Synced %s\n", proj.Name)
	}
}

func main() {
	dtStart := time.Now()
	syncAllProjects()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
