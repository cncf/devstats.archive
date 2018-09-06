package main

import (
	"database/sql"
	"fmt"
	"os"
	"regexp"
	"strconv"
	"strings"
	"time"

	lib "devstats"

	yaml "gopkg.in/yaml.v2"
)

// dbCommits holds all commits for given projec (DB connection)
type dbCommits struct {
	shas             []string
	repos            []string
	con              *sql.DB
	filesSkipPattern string
}

// dirExists checks if given path exist and if is a directory
func dirExists(path string) (bool, error) {
	if path[len(path)-1:] == "/" {
		path = path[:len(path)-1]
	}
	stat, err := os.Stat(path)
	if err != nil {
		if os.IsNotExist(err) {
			return false, nil
		}
		return false, err
	}
	if stat.IsDir() {
		return true, nil
	}
	return false, fmt.Errorf("%s: exists, but is not a directory", path)
}

// getRepos returns map { 'org' --> list of repos } for all devstats projects
func getRepos(ctx *lib.Ctx) (map[string]string, map[string][]string) {
	// Process all projects, or restrict from environment variable?
	onlyProjects := make(map[string]bool)
	selectedProjects := false
	if ctx.ProjectsCommits != "" {
		selectedProjects = true
		selProjs := strings.Split(ctx.ProjectsCommits, ",")
		for _, proj := range selProjs {
			onlyProjects[strings.TrimSpace(proj)] = true
		}
	}

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read defined projects
	data, err := lib.ReadFile(ctx, dataPrefix+ctx.ProjectsYaml)
	lib.FatalOnError(err)

	var projects lib.AllProjects
	lib.FatalOnError(yaml.Unmarshal(data, &projects))
	dbs := make(map[string]string)
	for name, proj := range projects.Projects {
		if lib.IsProjectDisabled(ctx, name, proj.Disabled) || (selectedProjects && !onlyProjects[name]) {
			continue
		}
		dbs[proj.PDB] = proj.FilesSkipPattern
	}

	allRepos := make(map[string][]string)
	for db := range dbs {
		// Connect to Postgres `db` database.
		con := lib.PgConnDB(ctx, db)
		defer func() { lib.FatalOnError(con.Close()) }()

		// Get list of orgs in a given database
		rows, err := con.Query("select distinct name from gha_repos where name like '%_/_%'")
		lib.FatalOnError(err)
		defer func() { lib.FatalOnError(rows.Close()) }()
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
				lib.Fatalf("invalid repo name: %s", repo)
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

// processRepo - processes single repo (clone or reset+pull) in a separate thread/goroutine
func processRepo(ch chan string, ctx *lib.Ctx, orgRepo, rwd string) {
	// Local or cron mode?
	cmdPrefix := ""
	if ctx.Local {
		cmdPrefix = lib.LocalGitScripts
	}

	// Clone or reset+pull repo
	exists, err := dirExists(rwd)
	lib.FatalOnError(err)
	if !exists {
		// We need to clone repo
		if ctx.Debug > 0 {
			lib.Printf("Cloning %s\n", orgRepo)
		}
		dtStart := time.Now()
		// Clone repo into given directory (from command line)
		// We cannot chdir because this is a multithreaded app
		// And all threads share CWD (current working directory)
		_, err := lib.ExecCommand(
			ctx,
			[]string{"git", "clone", "https://github.com/" + orgRepo + ".git", rwd},
			map[string]string{"GIT_TERMINAL_PROMPT": "0"},
		)
		dtEnd := time.Now()
		if err != nil {
			if ctx.Debug > 0 {
				lib.Printf("Warning git-clone failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), err)
			}
			fmt.Fprintf(os.Stderr, "Warning git-clone failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), err)
			ch <- ""
			return
		}
		if ctx.Debug > 0 {
			lib.Printf("Cloned %s: took %v\n", orgRepo, dtEnd.Sub(dtStart))
		}
	} else {
		// We *may* need to pull repo
		if ctx.Debug > 0 {
			lib.Printf("Pulling %s\n", orgRepo)
		}
		dtStart := time.Now()
		// Update repo using shell script that uses 'chdir'
		// We cannot chdir because this is a multithreaded app
		// And all threads share CWD (current working directory)
		_, err := lib.ExecCommand(
			ctx,
			[]string{cmdPrefix + "git_reset_pull.sh", rwd},
			map[string]string{"GIT_TERMINAL_PROMPT": "0"},
		)
		dtEnd := time.Now()
		if err != nil {
			if ctx.Debug > 0 {
				lib.Printf("Warning git_reset_pull.sh failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), err)
			}
			fmt.Fprintf(os.Stderr, "Warning git_reset_pull.sh failed: %s (took %v): %+v\n", orgRepo, dtEnd.Sub(dtStart), err)
			ch <- ""
			return
		}
		if ctx.Debug > 0 {
			lib.Printf("Pulled %s: took %v\n", orgRepo, dtEnd.Sub(dtStart))
		}
	}
	ch <- orgRepo
}

// processRepos process map of org -> list of repos to clone or pull them as needed
// it also displays cncf/gitdm needed info in debug mode (called manually)
func processRepos(ctx *lib.Ctx, allRepos map[string][]string) {
	// Set non-fatal exec mode, we want to run sync for next project(s) if current fails
	// Also set quite mode, many git-pulls or git-clones can fail and this is not needed to log it to DB
	// User can set higher debug level and run manually to debug this
	ctx.ExecFatal = false
	ctx.ExecQuiet = true

	// Go to main repos directory
	wd := ctx.ReposDir
	exists, err := dirExists(wd)
	lib.FatalOnError(err)
	if !exists {
		// Try to Mkdir it if not exists
		lib.FatalOnError(os.Mkdir(wd, 0755))
		exists, err = dirExists(wd)
		lib.FatalOnError(err)
		if !exists {
			lib.Fatalf("failed to create directory: %s", wd)
		}
	}

	// Process all orgs & repos
	thrN := lib.GetThreadsNum(ctx)
	ch := make(chan string)
	nThreads := 0
	allOkRepos := []string{}
	// Count all data
	checked := 0
	allN := 0
	lastTime := time.Now()
	dtStart := lastTime
	for _, repos := range allRepos {
		allN += len(repos)
	}
	// Process each repo only once
	seen := make(map[string]bool)
	// Iterate orgs
	for org, repos := range allRepos {
		// Go to current 'org' subdirectory
		owd := wd + org
		exists, err = dirExists(owd)
		lib.FatalOnError(err)
		if !exists {
			// Try to Mkdir it if not exists
			lib.FatalOnError(os.Mkdir(owd, 0755))
			exists, err = dirExists(owd)
			lib.FatalOnError(err)
			if !exists {
				lib.Fatalf("failed to create directory: %s", owd)
			}
		}
		// Iterate org's repositories
		for _, orgRepo := range repos {
			// Check if we already processed that repo
			_, ok := seen[orgRepo]
			if ok {
				continue
			}
			seen[orgRepo] = true
			// repository's working dir (if present we only need to do git reset --hard; git pull)
			ary := strings.Split(orgRepo, "/")
			repo := ary[1]
			rwd := owd + "/" + repo
			go processRepo(ch, ctx, orgRepo, rwd)
			nThreads++
			if nThreads == thrN {
				res := <-ch
				nThreads--
				if res != "" {
					allOkRepos = append(allOkRepos, res)
				}
				checked++
				lib.ProgressInfo(checked, allN, dtStart, &lastTime, time.Duration(10)*time.Second, orgRepo)
			}
		}
	}
	for nThreads > 0 {
		res := <-ch
		nThreads--
		if res != "" {
			allOkRepos = append(allOkRepos, res)
		}
		checked++
		lib.ProgressInfo(checked, allN, dtStart, &lastTime, time.Duration(10)*time.Second, "final join...")
	}

	// Output all repos as ruby object & Final cncf/gitdm command to generate concatenated git.log
	// Only output when GHA2DB_EXTERNAL_INFO env variable is set
	// Only output to stdout - not standard logs via lib.Printf(...)
	if ctx.ExternalInfo {
		// Sort list of repos and made them unique
		allOkRepos = lib.MakeUniqueSort(allOkRepos)

		// Create Ruby-like string with all repos array
		allOkReposStr := "[\n"
		for _, okRepo := range allOkRepos {
			allOkReposStr += "  '" + okRepo + "',\n"
		}
		allOkReposStr += "]"

		// Create list of orgs
		orgs := []string{}
		for org := range allRepos {
			orgs = append(orgs, org)
		}

		// Sort orgs and made them unique
		orgs = lib.MakeUniqueSort(orgs)

		// Output shell command sorted
		finalCmd := "./all_repos_log.sh "
		for _, org := range orgs {
			finalCmd += ctx.ReposDir + org + "/* "
		}

		// Output cncf/gitdm related data
		fmt.Printf("AllRepos:\n%s\n", allOkReposStr)
		fmt.Printf("Final command:\n%s\n", finalCmd)
	}
	lib.Printf("Sucesfully processed %d/%d repos\n", len(allOkRepos), checked)
}

// processCommitsDB creates/updates mapping between commits and list of files they refer to on databse 'db'
// using 'query' to get the list of unprocessed commits
func processCommitsDB(ch chan dbCommits, ctx *lib.Ctx, db, filesSkipPattern, query string) {
	// Result struct to be passed by the channel
	var commits dbCommits

	// Get list of unprocessed commits for current DB
	lib.Printf("Running on database: %s\n", db)
	dtStart := time.Now()
	// Connect to Postgres `db` database.
	con := lib.PgConnDB(ctx, db)

	rows, err := con.Query(query)
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(rows.Close()) }()
	var (
		sha  string
		repo string
	)
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&sha, &repo))
		commits.shas = append(commits.shas, sha)
		commits.repos = append(commits.repos, repo)
	}
	lib.FatalOnError(rows.Err())
	dtEnd := time.Now()
	lib.Printf("Database '%s' processed took %v, new commits: %d\n", db, dtEnd.Sub(dtStart), len(commits.shas))
	commits.con = con
	commits.filesSkipPattern = filesSkipPattern
	ch <- commits
}

// getCommitFiles get given commit's list of files and saves it in the database
func getCommitFiles(ch chan int, ctx *lib.Ctx, con *sql.DB, filesSkipPattern *regexp.Regexp, repo, sha string) {
	// Local or cron mode?
	cmdPrefix := ""
	if ctx.Local {
		cmdPrefix = lib.LocalGitScripts
	}

	// Get files using shell script that does 'chdir'
	// We cannot chdir because this is a multithreaded app
	// And all threads share CWD (current working directory)
	if ctx.Debug > 1 {
		lib.Printf("Getting files for commit %s:%s\n", repo, sha)
	}
	dtStart := time.Now()
	rwd := ctx.ReposDir + repo
	filesStr, err := lib.ExecCommand(
		ctx,
		[]string{cmdPrefix + "git_files.sh", rwd, sha},
		map[string]string{"GIT_TERMINAL_PROMPT": "0"},
	)
	dtEnd := time.Now()
	if err != nil {
		if ctx.Debug > 1 {
			lib.Printf("Warning git_files.sh failed: %s:%s (took %v): %+v\n", repo, sha, dtEnd.Sub(dtStart), err)
			fmt.Fprintf(os.Stderr, "Warning git_files.sh failed: %s:%s (took %v): %+v\n", repo, sha, dtEnd.Sub(dtStart), err)
		}
		lib.ExecSQLWithErr(
			con,
			ctx,
			lib.InsertIgnore("into gha_skip_commits(sha, dt) "+lib.NValues(2)),
			lib.AnyArray{sha, time.Now()}...,
		)
		ch <- -1
		return
	}
	files := strings.Split(filesStr, "\n")
	nFiles := 0
	var commitDate time.Time

	// Insert files in transaction: all or none
	tx, err := con.Begin()
	lib.FatalOnError(err)
	for i, data := range files {
		if i == 0 {
			unixTimeStamp, err := strconv.ParseInt(data, 10, 64)
			if err != nil {
				lib.Printf("Invalid time returned for repo: %s, sha: %s: '%s'\n", repo, sha, data)
			}
			lib.FatalOnError(err)
			commitDate = time.Unix(unixTimeStamp, 0)
			// fmt.Printf("unixTimeStamp: %v, commitDate: %v\n", unixTimeStamp, commitDate)
			continue
		}
		fileData := strings.TrimSpace(data)
		if fileData == "" {
			continue
		}
		// Use '♂♀' separator to avoid any character that can appear inside file name
		fileDataAry := strings.Split(fileData, "♂♀")
		if len(fileDataAry) != 2 {
			lib.Fatalf("invalid fileData returned for repo: %s, sha: %s: '%s'", repo, sha, fileData)
		}
		fileName := fileDataAry[0]
		// If file matches exclude pattern, skip it
		if fileName == "" || (filesSkipPattern != nil && filesSkipPattern.MatchString(fileName)) {
			continue
		}
		// fileSize can be:
		// > 0 - normal file size
		// 0 - file created - no contenets
		// -1 - file referenced in the commit SHA but not found in this commit (means deleted)
		// -2 - file size returned as "-" from git ls-tree - means some special file, directory
		fileSize, err := strconv.ParseInt(fileDataAry[1], 10, 64)
		if err != nil {
			fileSize = -2
		}
		// fmt.Printf("repo: %v, sha: %v, fileData: %v, fileDataAry: %v, fileName: %v, fileSize: %v\n", repo, sha, fileData, fileDataAry, fileName, fileSize)
		lib.ExecSQLTxWithErr(
			tx,
			ctx,
			lib.InsertIgnore("into gha_commits_files(sha, dt, path, size) "+lib.NValues(4)),
			lib.AnyArray{sha, commitDate, fileName, fileSize}...,
		)
		nFiles++
	}
	// Some commits have no files (for example only renames)
	// Mark them as skipped not to process again
	if nFiles == 0 {
		lib.ExecSQLTxWithErr(
			tx,
			ctx,
			lib.InsertIgnore("into gha_skip_commits(sha, dt) "+lib.NValues(2)),
			lib.AnyArray{sha, time.Now()}...,
		)
		// Commit transaction
		lib.FatalOnError(tx.Commit())
		ch <- 0
		return
	}
	// Commit transaction
	lib.FatalOnError(tx.Commit())
	if ctx.Debug > 1 {
		lib.Printf("Got %s:%s commit: %d files: took %v\n", repo, sha, nFiles, dtEnd.Sub(dtStart))
	}
	ch <- 1
}

// postprocessCommitsDB - calls given SQL on a given database
// to postprocess just created commit SHAs-files connections
func postprocessCommitsDB(ch chan int, ctx *lib.Ctx, con *sql.DB, query string) {
	_, err := con.Query(query)
	lib.FatalOnError(err)
	// Close connection
	lib.FatalOnError(con.Close())
	ch <- 1
}

// processCommits process all databases given in `dbs`
// on each database it creates/updates mapping between commits and list of files they refer to
// It is multithreaded processing up to NCPU databases at the same time
func processCommits(ctx *lib.Ctx, dbs map[string]string) {
	// Read SQL to get commits to sync from 'util_sql/list_unprocessed_commits.sql' file.
	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}
	bytes, err := lib.ReadFile(
		ctx,
		dataPrefix+"util_sql/list_unprocessed_commits.sql",
	)
	lib.FatalOnError(err)
	sqlQuery := string(bytes)

	// Process all DBs in a separate threads to get all commits
	dtStart := time.Now()
	thrN := lib.GetThreadsNum(ctx)
	chC := make(chan dbCommits)
	nThreads := 0
	allCommits := []dbCommits{}
	for db, filesSkipPattern := range dbs {
		go processCommitsDB(chC, ctx, db, filesSkipPattern, sqlQuery)
		nThreads++
		if nThreads == thrN {
			commits := <-chC
			nThreads--
			allCommits = append(allCommits, commits)
		}
	}
	for nThreads > 0 {
		commits := <-chC
		nThreads--
		allCommits = append(allCommits, commits)
	}
	dtEnd := time.Now()
	lib.Printf("Got new commits list: took %v\n", dtEnd.Sub(dtStart))

	// Set non-fatal exec mode, we want to run sync for next project(s) if current fails
	// Also set quite mode, many git-pulls or git-clones can fail and this is not needed to log it to DB
	// User can set higher debug level and run manually to debug this
	// Also set capture command's stdout mode
	ctx.ExecFatal = false
	ctx.ExecQuiet = true
	ctx.ExecOutput = true

	// Create final 'commits - file list' associations
	dtStart = time.Now()
	lastTime := dtStart
	statuses := make(map[int]int)
	// statuses:
	// -1: error
	// 0: commit without files
	// 1: commit with files
	statuses[-1] = 0
	statuses[0] = 0
	statuses[1] = 0
	allN := 0
	checked := 0
	// Count all commits
	for _, commits := range allCommits {
		allN += len(commits.shas)
	}
	// process all commits
	ch := make(chan int)
	nThreads = 0
	for _, commits := range allCommits {
		con := commits.con
		filesSkipPattern := commits.filesSkipPattern
		var re *regexp.Regexp
		if filesSkipPattern != "" {
			re = regexp.MustCompile(filesSkipPattern)
		}
		for i, sha := range commits.shas {
			repo := commits.repos[i]
			go getCommitFiles(ch, ctx, con, re, repo, sha)
			nThreads++
			if nThreads == thrN {
				statuses[<-ch]++
				nThreads--
				checked++
				lib.ProgressInfo(checked, allN, dtStart, &lastTime, time.Duration(10)*time.Second, repo)
			}
		}
	}
	for nThreads > 0 {
		statuses[<-ch]++
		nThreads--
		checked++
		lib.ProgressInfo(checked, allN, dtStart, &lastTime, time.Duration(10)*time.Second, "final join...")
	}
	dtEnd = time.Now()
	all := statuses[-1] + statuses[0] + statuses[1]
	perc := 0.0
	if all > 0 {
		perc = float64(statuses[1]) * 100.0 / (float64(all))
	}
	lib.Printf(
		"Got %d (%.2f%%) new commit's files, %d without files, %d failed, all %d, took %v\n",
		statuses[1],
		perc,
		statuses[0],
		statuses[-1],
		all,
		dtEnd.Sub(dtStart),
	)

	// Post execute SQL 'util_sql/create_events_commits.sql' on each database
	// This SQL updates 'gha_events_commits_files' table that
	// holds connections between commits SHA and events that refer to it
	// So we can query for files modified in the given events (via commits)
	dtStart = time.Now()
	bytes, err = lib.ReadFile(
		ctx,
		dataPrefix+"util_sql/create_events_commits.sql",
	)
	lib.FatalOnError(err)
	sqlQuery = string(bytes)
	ch = make(chan int)
	nThreads = 0
	for _, commits := range allCommits {
		con := commits.con
		go postprocessCommitsDB(ch, ctx, con, sqlQuery)
		nThreads++
		if nThreads == thrN {
			<-ch
			nThreads--
		}
	}
	for nThreads > 0 {
		<-ch
		nThreads--
	}
	dtEnd = time.Now()
	lib.Printf("Postprocessed all new commits, took %v\n", dtEnd.Sub(dtStart))
}

func main() {
	dtStart := time.Now()
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()
	if !ctx.SkipGetRepos {
		dbs, repos := getRepos(&ctx)
		if len(dbs) == 0 {
			lib.Fatalf("No databases to process")
		}
		if len(repos) == 0 {
			lib.Fatalf("No repos to process")
		}
		if ctx.ProcessRepos {
			processRepos(&ctx, repos)
		}
		if ctx.ProcessCommits {
			processCommits(&ctx, dbs)
		}
	}
	dtEnd := time.Now()
	lib.Printf("All repos processed in: %v\n", dtEnd.Sub(dtStart))
}
