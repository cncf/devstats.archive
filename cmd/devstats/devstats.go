package main

import (
	lib "devstats"
	"fmt"
	"io/ioutil"
	"os"
	"sort"
	"time"

	yaml "gopkg.in/yaml.v2"
)

// Sync all projects from "projects.yaml", calling `gha2db_sync` for all of them
func syncAllProjects() bool {
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

	var projects lib.AllProjects
	lib.FatalOnError(yaml.Unmarshal(data, &projects))

	// Create PID file (if not exists)
	// If PID file exists, exit
	pid := os.Getpid()
	pidFile := "/tmp/devstats.pid"
	f, err := os.OpenFile(pidFile, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0700)
	if err != nil {
		lib.Printf("Another `devstats` instance is running, PID file '%s' exists, exiting\n", pidFile)
		return false
	}
	fmt.Fprintf(f, "%d", pid)
	f.Close()

	// Schedule remove PID file when finished
	defer func() {
		lib.FatalOnError(os.Remove(pidFile))
	}()

	// Sort projects by "order"
	orders := []int{}
	projectsMap := make(map[int]string)
	for name, proj := range projects.Projects {
		if proj.Disabled {
			continue
		}
		orders = append(orders, proj.Order)
		projectsMap[proj.Order] = name
	}
	sort.Ints(orders)

	// Sync all projects
	for _, order := range orders {
		name := projectsMap[order]
		proj := projects.Projects[name]
		lib.Printf("Syncing #%d %s\n", order, name)
		dtStart := time.Now()
		res := lib.ExecCommand(
			&ctx,
			[]string{
				cmdPrefix + "gha2db_sync",
			},
			map[string]string{
				"GHA2DB_PROJECT": name,
				"PG_DB":          proj.PDB,
				"IDB_DB":         proj.IDB,
			},
		)
		dtEnd := time.Now()
		if res != nil {
			lib.Printf("Error result for %s (took %v): %+v\n", name, dtEnd.Sub(dtStart), res)
			fmt.Fprintf(os.Stderr, "%v: Error result for %s (took %v): %+v\n", dtEnd, name, dtEnd.Sub(dtStart), res)
			continue
		}
		lib.Printf("Synced %s, took: %v\n", name, dtEnd.Sub(dtStart))
	}
	return true
}

func main() {
	dtStart := time.Now()
	synced := syncAllProjects()
	dtEnd := time.Now()
	if synced {
		lib.Printf("Synced all projects in: %v\n", dtEnd.Sub(dtStart))
	}
}
