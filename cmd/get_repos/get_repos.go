package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"sort"
	"strings"
	"time"

	lib "devstats"

	yaml "gopkg.in/yaml.v2"
)

// processOrg - processes all entries in a single org (subdirectory) - clones or pulls repo
func processOrg(ctx *lib.Ctx, org string, repos []string) (okRepos []string) {
	// Go to main repos directory
	wd := ctx.ReposDir
	err := os.Chdir(wd)
	if err != nil {
		// Try to Mkdir it if not exists
		lib.FatalOnError(os.Mkdir(wd, 0755))
		lib.FatalOnError(os.Chdir(wd))
	}

	// Go to current 'org' subdirectory
	wd += org
	err = os.Chdir(wd)
	if err != nil {
		// Try to Mkdir it if not exists
		lib.FatalOnError(os.Mkdir(wd, 0755))
		lib.FatalOnError(os.Chdir(wd))
	}

	// Iterate org's repositories
	for _, orgRepo := range repos {
		// Must be in org directory for every repo call
		lib.FatalOnError(os.Chdir(wd))

		// repository's working dir (if present we only need to do git reset --hard; git pull)
		ary := strings.Split(orgRepo, "/")
		repo := ary[1]
		rwd := wd + "/" + repo
		err = os.Chdir(rwd)
		if err != nil {
			// We need to clone repo
			if ctx.Debug > 0 {
				lib.Printf("Cloning %s\n", orgRepo)
			}
			dtStart := time.Now()
			res := lib.ExecCommand(
				ctx,
				[]string{"git", "clone", "https://github.com/" + orgRepo + ".git"},
				map[string]string{"GIT_TERMINAL_PROMPT": "0"},
			)
			dtEnd := time.Now()
			if res != nil {
				if ctx.Debug > 0 {
					lib.Printf("Warining git-clone failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), res)
				}
				fmt.Fprintf(os.Stderr, "Warining git-clone failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), res)
				continue
			}
			pwd, _ := os.Getwd()
			if ctx.Debug > 0 {
				lib.Printf("Cloned %s (took %v) in %s\n", orgRepo, dtEnd.Sub(dtStart), pwd)
			}
			okRepos = append(okRepos, orgRepo)
		} else {
			// We *may* need to pull repo
			if ctx.Debug > 0 {
				lib.Printf("Pulling %s\n", orgRepo)
			}
			dtStart := time.Now()
			res := lib.ExecCommand(
				ctx,
				[]string{"git", "reset", "--hard"},
				map[string]string{"GIT_TERMINAL_PROMPT": "0"},
			)
			dtEnd := time.Now()
			if res != nil {
				if ctx.Debug > 0 {
					lib.Printf("Warining git-reset failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), res)
				}
				fmt.Fprintf(os.Stderr, "Warining git-reset failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), res)
				continue
			}
			res = lib.ExecCommand(
				ctx,
				[]string{"git", "pull"},
				map[string]string{"GIT_TERMINAL_PROMPT": "0"},
			)
			dtEnd = time.Now()
			if res != nil {
				if ctx.Debug > 0 {
					lib.Printf("Warining git-pull failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), res)
				}
				fmt.Fprintf(os.Stderr, "Warining git-pull failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), res)
				continue
			}
			pwd, _ := os.Getwd()
			if ctx.Debug > 0 {
				lib.Printf("Pulled %s (took %v) in %s\n", orgRepo, dtEnd.Sub(dtStart), pwd)
			}
			okRepos = append(okRepos, orgRepo)
		}
	}

	// return list of successfully processed repos
	return
}

// getRepos returns map { 'org' --> list of repos } for all devstats projects
func getRepos(ctx *lib.Ctx) (map[string]bool, map[string][]string) {
	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read defined projects
	data, err := ioutil.ReadFile(dataPrefix + "projects.yaml")
	lib.FatalOnError(err)

	var projects lib.AllProjects
	lib.FatalOnError(yaml.Unmarshal(data, &projects))
	dbs := make(map[string]bool)
	for _, proj := range projects.Projects {
		if proj.Disabled {
			continue
		}
		dbs[proj.PDB] = true
	}

	allRepos := make(map[string][]string)
	for db := range dbs {
		// Connect to Postgres `db` database.
		con := lib.PgConnDB(ctx, db)
		defer con.Close()

		// Get list of orgs in a given database
		rows, err := con.Query("select distinct name from gha_repos where name like '%/%'")
		lib.FatalOnError(err)
		defer rows.Close()
		var (
			repo  string
			repos []string
		)
		for rows.Next() {
			lib.FatalOnError(rows.Scan(&repo))
			repos = append(repos, repo)
		}
		lib.FatalOnError(rows.Err())

		// Create map of distinct "org" --> list of repos
		for _, repo := range repos {
			ary := strings.Split(repo, "/")
			if len(ary) != 2 {
				lib.FatalOnError(fmt.Errorf("invalid repo name: %s", repo))
			}
			org := ary[0]
			_, ok := allRepos[org]
			if !ok {
				allRepos[org] = []string{}
			}
			ary = append(allRepos[org], repo)
			allRepos[org] = ary
		}
	}

	// return final map
	return dbs, allRepos
}

// processRepos process map of org -> list of repos to clone or pull them as needed
// it also displays cncf/gitdm needed info in debug mode (called manually)
// It is *singlethreaded* because it changes directories often and os.Chdir() affects all goroutines.
func processRepos(ctx *lib.Ctx, allRepos map[string][]string) {
	// Set non-fatal exec mode, we want to run sync for next project(s) if current fails
	// Also set quite mode, many git-pulls or git-clones can fail and this is not needed to log it to DB
	// User can set higher debug level and run manually to debug this
	ctx.ExecFatal = false
	ctx.ExecQuiet = true

	// Remeber current dir
	pwd, err := os.Getwd()
	lib.FatalOnError(err)

	// Process all orgs
	finalCmd := "./all_repos_log.sh "
	allOkRepos := []string{}
	for org, repos := range allRepos {
		okRepos := processOrg(ctx, org, repos)
		for _, okRepo := range okRepos {
			allOkRepos = append(allOkRepos, okRepo)
		}
		finalCmd += ctx.ReposDir + org + "/* "
	}

	// Return to staring directory
	lib.FatalOnError(os.Chdir(pwd))

	// Output all repos as ruby object & Final cncf/gitdm command to generate concatenated git.log
	// Only output when GHA2DB_EXTERNAL_INFO env variable is set
	// Only output to stdout - not standard logs via lib.Printf(...)
	if ctx.ExternalInfo {
		// Sort list of repos
		sort.Strings(allOkRepos)

		// Create Ruby-like string
		allOkReposStr := "[\n"
		for _, okRepo := range allOkRepos {
			allOkReposStr += "  '" + okRepo + "',\n"
		}
		allOkReposStr += "]"

		// Output
		fmt.Printf("AllRepos:\n%s\n", allOkReposStr)
		fmt.Printf("Final command:\n%s\n", finalCmd)
	}
}

// processCommitsDB creates/updates mapping between commits and list of files they refer to on databse 'db'
// using 'query' to get liist of unprocessed commits
func processCommitsDB(ch chan bool, ctx *lib.Ctx, db, query string) {
	// Conditional info
	if ctx.Debug > 0 {
		lib.Printf("Running on database: %s\n", db)
	}

	// Close channel on end no matter what happens
	defer func() {
		if ch != nil {
			ch <- true
		}
	}()

	// Get list of unprocessed commits for current DB
	dtStart := time.Now()
	// Connect to Postgres `db` database.
	con := lib.PgConnDB(ctx, db)
	defer con.Close()

	rows, err := con.Query(query)
	lib.FatalOnError(err)
	defer rows.Close()
	var (
		sha  string
		shas []string
	)
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&sha))
		shas = append(shas, sha)
	}
	lib.FatalOnError(rows.Err())
	dtEnd := time.Now()
	if ctx.Debug > 0 {
		lib.Printf("Database '%s' processed in %v, commits: %d\n", db, dtEnd.Sub(dtStart), len(shas))
	}
}

// processCommits process all databases given in `dbs`
// on each database it creates/updates mapping between commits and list of files they refer to
// It is multithreaded processing up to NCPU databases at the same time
func processCommits(ctx *lib.Ctx, dbs map[string]bool) {
	// Read SQL to get commits to sync from 'util_sql/list_unprocessed_commits.sql' file.
	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}
	bytes, err := ioutil.ReadFile(
		dataPrefix + "util_sql/list_unprocessed_commits.sql",
	)
	lib.FatalOnError(err)
	sqlQuery := string(bytes)

	// Process all DBs in a separate threads
	thrN := lib.GetThreadsNum(ctx)
	chanPool := []chan bool{}
	for db := range dbs {
		ch := make(chan bool)
		chanPool = append(chanPool, ch)
		go processCommitsDB(ch, ctx, db, sqlQuery)
		if len(chanPool) == thrN {
			ch = chanPool[0]
			<-ch
			chanPool = chanPool[1:]
		}
	}
	for _, ch := range chanPool {
		<-ch
	}
}

func main() {
	dtStart := time.Now()
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()
	dbs, repos := getRepos(&ctx)
	if ctx.ProcessRepos {
		processRepos(&ctx, repos)
	}
	if ctx.ProcessCommits {
		processCommits(&ctx, dbs)
	}
	dtEnd := time.Now()
	lib.Printf("All repos processed in: %v\n", dtEnd.Sub(dtStart))
}
