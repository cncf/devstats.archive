package main

import (
	"crypto/sha1"
	lib "devstats"
	"encoding/csv"
	"encoding/hex"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"sort"
	"strings"
	"time"

	yaml "gopkg.in/yaml.v2"
)

type replaceConfig struct {
	table  string
	column string
}

func getHidden(configFile string) map[string]string {
	shaMap := make(map[string]string)
	f, err := os.Open(configFile)
	if err == nil {
		defer f.Close()
		reader := csv.NewReader(f)
		for {
			row, err := reader.Read()
			if err == io.EOF {
				break
			} else if err != nil {
				lib.FatalOnError(err)
			}
			sha := row[0]
			if sha == "sha1" {
				continue
			}
			shaMap[sha] = "anon-" + sha
		}
	}
	return shaMap
}

func processHidden(ctx *lib.Ctx) {
	replaces := []replaceConfig{
		{
			table:  "gha_actors",
			column: "login",
		},
		{
			table:  "gha_actors",
			column: "name",
		},
		{
			table:  "gha_actors_emails",
			column: "email",
		},
		{
			table:  "gha_actors_affiliations",
			column: "company_name",
		},
		{
			table:  "gha_companies",
			column: "name",
		},
		{
			table:  "gha_events",
			column: "dup_actor_login",
		},
		{
			table:  "gha_payloads",
			column: "dup_actor_login",
		},
		{
			table:  "gha_commits",
			column: "dup_actor_login",
		},
		{
			table:  "gha_commits",
			column: "author_name",
		},
		{
			table:  "gha_pages",
			column: "dup_actor_login",
		},
		{
			table:  "gha_comments",
			column: "dup_actor_login",
		},
		{
			table:  "gha_comments",
			column: "dup_user_login",
		},
		{
			table:  "gha_issues",
			column: "dup_actor_login",
		},
		{
			table:  "gha_issues",
			column: "dup_actor_login",
		},
		{
			table:  "gha_issues",
			column: "dup_user_login",
		},
		{
			table:  "gha_milestones",
			column: "dup_actor_login",
		},
		{
			table:  "gha_milestones",
			column: "dupn_creator_login",
		},
		{
			table:  "gha_issues_labels",
			column: "dup_actor_login",
		},
		{
			table:  "gha_forkees",
			column: "dup_actor_login",
		},
		{
			table:  "gha_forkees",
			column: "dup_owner_login",
		},
		{
			table:  "gha_releases",
			column: "dup_actor_login",
		},
		{
			table:  "gha_releases",
			column: "dup_author_login",
		},
		{
			table:  "gha_assets",
			column: "dup_actor_login",
		},
		{
			table:  "gha_assets",
			column: "dup_uploader_login",
		},
		{
			table:  "gha_pull_requests",
			column: "dup_actor_login",
		},
		{
			table:  "gha_pull_requests",
			column: "dup_user_login",
		},
		{
			table:  "gha_branches",
			column: "dupn_forkee_name",
		},
		{
			table:  "gha_branches",
			column: "dupn_user_login",
		},
		{
			table:  "gha_teams",
			column: "dup_actor_login",
		},
		{
			table:  "gha_texts",
			column: "actor_login",
		},
		{
			table:  "gha_issues_events_labels",
			column: "actor_login",
		},
	}
	configFile := lib.HideCfgFile
	shaMap := getHidden(configFile)

	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	data, err := ioutil.ReadFile(dataPrefix + ctx.ProjectsYaml)
	lib.FatalOnError(err)

	var projects lib.AllProjects
	lib.FatalOnError(yaml.Unmarshal(data, &projects))

	orders := []int{}
	projectsMap := make(map[int]string)
	for name, proj := range projects.Projects {
		if lib.IsProjectDisabled(ctx, name, proj.Disabled) {
			continue
		}
		orders = append(orders, proj.Order)
		projectsMap[proj.Order] = name
	}
	sort.Ints(orders)

	only := make(map[string]struct{})
	onlyS := os.Getenv("ONLY")
	bOnly := false
	if onlyS != "" {
		onlyA := strings.Split(onlyS, " ")
		for _, item := range onlyA {
			if item == "" {
				continue
			}
			only[item] = struct{}{}
		}
		bOnly = true
	}

	tasks := [][3]string{}
	dbs := []string{}
	for _, order := range orders {
		name := projectsMap[order]
		if bOnly {
			_, ok := only[name]
			if !ok {
				continue
			}
		}
		proj := projects.Projects[name]
		for sha, anon := range shaMap {
			tasks = append(tasks, [3]string{proj.PDB, sha, anon})
		}
		dbs = append(dbs, proj.PDB)
	}
	thrN := lib.GetThreadsNum(ctx)
	ch := make(chan bool)
	nThreads := 0
	for _, task := range tasks {
		go func(ch chan bool, task [3]string) {
			con := lib.PgConnDB(ctx, task[0])
			defer func() { lib.FatalOnError(con.Close()) }()
			for _, replace := range replaces {
				res := lib.ExecSQLWithErr(
					con,
					ctx,
					fmt.Sprintf(
						"update %s set %s = %s where encode(digest(%s, 'sha1'), 'hex') = %s",
						replace.table,
						replace.column,
						lib.NValue(1),
						replace.column,
						lib.NValue(2),
					),
					lib.AnyArray{
						task[2],
						task[1],
					}...,
				)
				rows, err := res.RowsAffected()
				lib.FatalOnError(err)
				if rows > 0 {
					lib.Printf("DB: %s, table: %s, column: %s, sha: %s, updated %d rows\n", task[0], replace.table, replace.column, task[1], rows)
				}
			}
			ch <- true
		}(ch, task)
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
}

func hideData(args []string) {
	configFile := lib.HideCfgFile
	shaMap := getHidden(configFile)
	added := false
	for _, argo := range args {
		arg := strings.TrimSpace(argo)
		hash := sha1.New()
		hash.Write([]byte(arg))
		sha := hex.EncodeToString(hash.Sum(nil))
		_, ok := shaMap[sha]
		if ok {
			lib.Printf("Skipping '%s', SHA1 '%s' - already added\n", arg, sha)
			continue
		}
		shaMap[sha] = ""
		added = true
	}
	if !added {
		return
	}
	var writer *csv.Writer
	oFile, err := os.Create(configFile)
	lib.FatalOnError(err)
	defer func() { _ = oFile.Close() }()
	writer = csv.NewWriter(oFile)
	defer writer.Flush()
	err = writer.Write([]string{"sha1"})
	lib.FatalOnError(err)
	for sha := range shaMap {
		err = writer.Write([]string{sha})
		lib.FatalOnError(err)
	}
}

func main() {
	var ctx lib.Ctx
	dtStart := time.Now()
	ctx.Init()
	if len(os.Args) < 2 {
		processHidden(&ctx)
	} else {
		hideData(os.Args[1:])
	}
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
