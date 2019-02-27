package main

import (
	lib "devstats"
	"fmt"
	"io/ioutil"
	"os"
	"time"

	yaml "gopkg.in/yaml.v2"
)

// Sync all projects from "projects.yaml", calling `gha2db_sync` for all of them
func syncAllProjects() bool {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Local or cron mode?
	cmdPrefix := ""
	dataPrefix := ctx.DataDir
	if ctx.Local {
		cmdPrefix = "./"
		dataPrefix = "./"
	}

	// Read defined projects
	data, err := ioutil.ReadFile(dataPrefix + ctx.ProjectsYaml)
	lib.FatalOnError(err)

	var projects lib.AllProjects
	lib.FatalOnError(yaml.Unmarshal(data, &projects))

	// Get ordered & filtered projects
	names, projs := lib.GetProjectsList(&ctx, &projects)

	// If check provision flag is set, we need to iterate all projects
	// and check if all of them are provisioned
	if ctx.CheckProvisionFlag {
		missing := 0
		for _, proj := range projs {
			db := proj.PDB
			con := lib.PgConnDB(&ctx, db)
			provisionFlag := "provisioned"
			rows := lib.QuerySQLWithErr(con, &ctx, "select 1 from gha_computed where metric = "+lib.NValue(1)+" limit 1", provisionFlag)
			provisioned := 0
			for rows.Next() {
				lib.FatalOnError(rows.Scan(&provisioned))
			}
			lib.FatalOnError(rows.Err())
			lib.FatalOnError(rows.Close())
			lib.FatalOnError(con.Close())
			if provisioned != 1 {
				lib.Printf("Missing provisioned flag on '%s' database and check provisioned flag is set\n", db)
				missing++
			}
		}
		if missing > 0 {
			lib.Printf("Not all databases provisioned, pending: %d, exiting\n", missing)
			return false
		}
	}

	// Set non-fatal exec mode, we want to run sync for next project(s) if current fails
	ctx.ExecFatal = false

	if !ctx.SkipPIDFile {
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
		lib.FatalOnError(f.Close())

		// Schedule remove PID file when finished
		defer func() { lib.FatalOnError(os.Remove(pidFile)) }()
	}

	// Only run clone/pull part here
	// Remaining commit analysis in"gha2db_sync"
	// after new commits are fetched from GHA
	// So here we get repo files to the newest state
	// And the gha2db_sync takes Postgres DB commits to the newest state
	// after this it need to update commit files
	if !ctx.SkipGetRepos {
		lib.Printf("Updating git repos for all projects\n")
		dtStart := time.Now()
		_, res := lib.ExecCommand(
			&ctx,
			[]string{
				cmdPrefix + "get_repos",
			},
			map[string]string{
				"GHA2DB_PROCESS_REPOS": "1",
			},
		)
		dtEnd := time.Now()
		if res != nil {
			lib.Printf("Error updating git repos (took %v): %+v\n", dtEnd.Sub(dtStart), res)
			fmt.Fprintf(os.Stderr, "%v: Error updating git repos (took %v): %+v\n", dtEnd, dtEnd.Sub(dtStart), res)
			return false
		}
		lib.Printf("Updated git repos, took: %v\n", dtEnd.Sub(dtStart))
	}

	// Sync all projects
	for i, name := range names {
		proj := projs[i]
		projEnv := map[string]string{
			"GHA2DB_PROJECT": name,
			"PG_DB":          proj.PDB,
			"ENV_SET":        "1",
		}
		// Apply eventual per project specific environment
		for envName, envValue := range proj.Env {
			projEnv[envName] = envValue
		}
		lib.Printf("Syncing #%d %s\n", proj.Order, name)
		dtStart := time.Now()
		_, res := lib.ExecCommand(
			&ctx,
			[]string{
				cmdPrefix + "gha2db_sync",
			},
			projEnv,
		)
		dtEnd := time.Now()
		if res != nil {
			lib.Printf("Error result for %s (took %v): %+v\n", name, dtEnd.Sub(dtStart), res)
			fmt.Fprintf(os.Stderr, "%v: Error result for %s (took %v): %+v\n", dtEnd, name, dtEnd.Sub(dtStart), res)
			continue
		}
		lib.Printf("Synced %s, took: %v\n", name, dtEnd.Sub(dtStart))
	}
	if ctx.WebsiteData {
		lib.Printf("Generating website data for all projects\n")
		dtStart := time.Now()
		_, res := lib.ExecCommand(
			&ctx,
			[]string{
				cmdPrefix + "website_data",
			},
			nil,
		)
		dtEnd := time.Now()
		if res != nil {
			lib.Printf("Error generating website data (took %v): %+v\n", dtEnd.Sub(dtStart), res)
			fmt.Fprintf(os.Stderr, "%v: Error generating website (took %v): %+v\n", dtEnd, dtEnd.Sub(dtStart), res)
			return false
		}
		lib.Printf("Generated website data, took: %v\n", dtEnd.Sub(dtStart))
	}
	return true
}

func main() {
	dtStart := time.Now()
	synced := syncAllProjects()
	dtEnd := time.Now()
	if synced {
		lib.Printf("Synced all projects in: %v\n", dtEnd.Sub(dtStart))
	} else {
		lib.Printf("There were sync errors, took: %v\n", dtEnd.Sub(dtStart))
	}
}
