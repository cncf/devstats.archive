package main

import (
	"database/sql"
	lib "devstats"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
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

func getIntValue(con *sql.DB, ctx *lib.Ctx, sql string) (ival int) {
	rows := lib.QuerySQLWithErr(con, ctx, sql)
	defer func() { lib.FatalOnError(rows.Close()) }()
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&ival))
	}
	lib.FatalOnError(rows.Err())
	return
}

func generateJSONData(ctx *lib.Ctx, name, excludeBots, lastTagCmd, repo string, stats *projectStats) {
	if name == "kubernetes" {
		name = "gha"
	} else if name == "all" {
		name = "allprj"
	}
	// Connect to Postgres DB
	con := lib.PgConnDB(ctx, name)
	defer func() { lib.FatalOnError(con.Close()) }()
	for i := 0; i < 24; i++ {
		to := 23 - i
		from := to + 1
		commits := getIntValue(
			con,
			ctx,
			fmt.Sprintf(
				"select count(distinct sha) from gha_commits "+
					"where dup_created_at >= now() - '%d hours'::interval "+
					"and dup_created_at < now() - '%d hours'::interval ",
				from,
				to,
			)+"and (lower(dup_actor_login) "+excludeBots+")",
		)
		stats.CommitGraph.Day[i][0] = i
		stats.CommitGraph.Day[i][1] = commits
	}
	for i := 0; i < 7; i++ {
		to := 6 - i
		from := to + 1
		commits := getIntValue(
			con,
			ctx,
			fmt.Sprintf(
				"select count(distinct sha) from gha_commits "+
					"where dup_created_at >= now() - '%d days'::interval "+
					"and dup_created_at < now() - '%d days'::interval ",
				from,
				to,
			)+"and (lower(dup_actor_login) "+excludeBots+")",
		)
		stats.CommitGraph.Week[i][0] = i
		stats.CommitGraph.Week[i][1] = commits
	}
	for i := 0; i < 4; i++ {
		to := 3 - i
		from := to + 1
		commits := getIntValue(
			con,
			ctx,
			fmt.Sprintf(
				"select count(distinct sha) from gha_commits "+
					"where dup_created_at >= now() - '%d weeks'::interval "+
					"and dup_created_at < now() - '%d weeks'::interval ",
				from,
				to,
			)+"and (lower(dup_actor_login) "+excludeBots+")",
		)
		stats.CommitGraph.Month[i][0] = i
		stats.CommitGraph.Month[i][1] = commits
	}
	stats.Totals.Day.Commits = stats.CommitGraph.Week[6][1]
	stats.Totals.Week.Commits = stats.CommitGraph.Month[3][1]
	stats.Totals.Month.Commits = getIntValue(
		con,
		ctx,
		"select count(distinct sha) from gha_commits "+
			"where dup_created_at >= now() - '1 month'::interval "+
			"and (lower(dup_actor_login) "+excludeBots+")",
	)
	stats.Totals.Day.Discussion = getIntValue(
		con,
		ctx,
		"select count(distinct event_id) from gha_texts "+
			"where created_at >= now() - '1 day'::interval "+
			"and (lower(actor_login) "+excludeBots+")",
	)
	stats.Totals.Week.Discussion = getIntValue(
		con,
		ctx,
		"select count(distinct event_id) from gha_texts "+
			"where created_at >= now() - '1 week'::interval "+
			"and (lower(actor_login) "+excludeBots+")",
	)
	stats.Totals.Month.Discussion = getIntValue(
		con,
		ctx,
		"select count(distinct event_id) from gha_texts "+
			"where created_at >= now() - '1 month'::interval "+
			"and (lower(actor_login) "+excludeBots+")",
	)
	stats.RecentDiscussion = stats.Totals.Month.Discussion
	stats.Totals.Day.Stars = getIntValue(
		con,
		ctx,
		"select coalesce(sum(sub.diff), 0) "+
			"from (select min(stargazers_count) as fmin, "+
			"max(stargazers_count) - min(stargazers_count) as diff "+
			"from gha_forkees where dup_repo_name = full_name and "+
			"dup_created_at >= now() - '1 day'::interval "+
			"group by dup_repo_name) sub where fmin > 0 and diff > 0",
	)
	stats.Totals.Week.Stars = getIntValue(
		con,
		ctx,
		"select coalesce(sum(sub.diff), 0) "+
			"from (select min(stargazers_count) as fmin, "+
			"max(stargazers_count) - min(stargazers_count) as diff "+
			"from gha_forkees where dup_repo_name = full_name and "+
			"dup_created_at >= now() - '1 week'::interval "+
			"group by dup_repo_name) sub where fmin > 0 and diff > 0",
	)
	stats.Totals.Month.Stars = getIntValue(
		con,
		ctx,
		"select coalesce(sum(sub.diff), 0) "+
			"from (select min(stargazers_count) as fmin, "+
			"max(stargazers_count) - min(stargazers_count) as diff "+
			"from gha_forkees where dup_repo_name = full_name and "+
			"dup_created_at >= now() - '1 month'::interval "+
			"group by dup_repo_name) sub where fmin > 0 and diff > 0",
	)
	stats.Totals.Month.Stars = getIntValue(
		con,
		ctx,
		"select coalesce(sum(sub.diff), 0) "+
			"from (select min(stargazers_count) as fmin, "+
			"max(stargazers_count) - min(stargazers_count) as diff "+
			"from gha_forkees where dup_repo_name = full_name and "+
			"dup_created_at >= now() - '1 month'::interval "+
			"group by dup_repo_name) sub where fmin > 0 and diff > 0",
	)
	stats.Stars = getIntValue(
		con,
		ctx,
		"select sum(fmax) from (select max(stargazers_count) as fmax "+
			"from gha_forkees where dup_repo_name = full_name "+
			"and dup_created_at >= now() - '3 months'::interval "+
			"group by dup_repo_name) sub",
	)
	stats.OpenIssues = getIntValue(
		con,
		ctx,
		"select count(sub.id) from (select distinct id, "+
			"last_value(closed_at) over update_date as closed_at "+
			"from gha_issues where is_pull_request = false "+
			"window update_date as (partition by id order by "+
			"updated_at asc, event_id asc range between current row "+
			"and unbounded following)) sub where sub.closed_at is null",
	)
	tag := "-"
	if repo != "" {
		var err error
		rwd := ctx.ReposDir + repo
		tag, err = lib.ExecCommand(
			ctx,
			[]string{lastTagCmd, rwd},
			map[string]string{"GIT_TERMINAL_PROMPT": "0"},
		)
		if err == nil {
			tag = strings.TrimSpace(tag)
		}
	}
	stats.LatestVersion = tag
}

func generateWebsiteData() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// We need this to capture 'last_tag.sh' output.
	ctx.ExecOutput = true
	ctx.ExecFatal = false

	// Local or cron mode?
	dataPrefix := lib.DataDir
	cmdPrefix := ""
	if ctx.Local {
		dataPrefix = "./"
		cmdPrefix = lib.LocalGitScripts
	}
	lastTagCmd := cmdPrefix + "last_tag.sh"

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

	// Read bots exclusion partial SQL
	bytes, err := lib.ReadFile(&ctx, dataPrefix+"util_sql/exclude_bots.sql")
	lib.FatalOnError(err)
	excludeBots := string(bytes)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)

	if thrN > 1 {
		ch := make(chan struct{})
		nThreads := 0
		for name, stats := range pstats {
			go func(ch chan struct{}, name string, stats projectStats) {
				generateJSONData(&ctx, name, excludeBots, lastTagCmd, projects.Projects[name].MainRepo, &stats)
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
			generateJSONData(&ctx, name, excludeBots, lastTagCmd, projects.Projects[name].MainRepo, &stats)
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
