package main

import (
	"bytes"
	"compress/gzip"
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	lib "k8s.io/test-infra/gha2db"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

// Ctx - environment context packed in structure
type Ctx struct {
	Debug   int
	jsonOut bool
	dbOut   bool
}

// Inserts single GHA Actor
func ghaActor(con *sql.DB, actor lib.Actor) {
	// gha_actors
	// {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592,
	// "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
	// {"id"=>8, "login"=>34, "display_login"=>34, "gravatar_id"=>0, "url"=>63, "avatar_url"=>49}
	lib.ExecSQLWithErr(
		con,
		lib.InsertIgnore("into gha_actors(id, login) "+lib.NValues(2)),
		lib.AnyArray{actor.ID, actor.Login}...,
	)
}

func writeToDB(ctx Ctx, con *sql.DB, ev lib.Event) int {
	// gha_events
	// {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592,
	// "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592,
	// "org:Hash"=>19451}
	// {"id"=>10, "type"=>29, "actor"=>278, "repo"=>290, "payload"=>216017, "public"=>4,
	// "created_at"=>20, "org"=>230}
	// Fields actor_login, repo_name are copied from (gha_actors and gha_repos) to save
	// joins on complex queries (MySQL has no hash joins and is very slow on big tables joins)
	eventID := ev.ID
	rows := lib.QuerySQLWithErr(con, fmt.Sprintf("select 1 from gha_events where id=%s", lib.NValue(1)), eventID)
	defer rows.Close()
	exists := 0
	for rows.Next() {
		exists = 1
	}
	if exists == 1 {
		return 0
	}
	lib.ExecSQLWithErr(
		con,
		"insert into gha_events("+
			"id, type, actor_id, repo_id, public, created_at, "+
			"actor_login, repo_name, org_id) "+lib.NValues(9),
		lib.AnyArray{
			eventID,
			ev.Type,
			ev.Actor.ID,
			ev.Repo.ID,
			ev.Public,
			ev.CreatedAt,
			ev.Actor.Login,
			ev.Repo.Name,
			lib.OrgIDOrNil(ev.Org),
		}...,
	)

	// gha_actors
	ghaActor(con, ev.Actor)

	// gha_repos
	// {"id:Fixnum"=>48592, "name:String"=>48592, "url:String"=>48592}
	// {"id"=>8, "name"=>111, "url"=>140}
	repo := ev.Repo
	lib.ExecSQLWithErr(
		con,
		lib.InsertIgnore("into gha_repos(id, name) "+lib.NValues(2)),
		lib.AnyArray{repo.ID, repo.Name}...,
	)

	// gha_orgs
	// {"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494,
	// "url:String"=>18494, "avatar_url:String"=>18494}
	// {"id"=>8, "login"=>38, "gravatar_id"=>0, "url"=>66, "avatar_url"=>49}
	org := ev.Org
	if org != nil {
		lib.ExecSQLWithErr(
			con,
			lib.InsertIgnore("into gha_orgs(id, login) "+lib.NValues(2)),
			lib.AnyArray{org.ID, org.Login}...,
		)
	}

	// gha_payloads
	// {"push_id:Fixnum"=>24636, "size:Fixnum"=>24636, "distinct_size:Fixnum"=>24636,
	// "ref:String"=>30522, "head:String"=>24636, "before:String"=>24636, "commits:Array"=>24636,
	// "action:String"=>14317, "issue:Hash"=>6446, "comment:Hash"=>6055, "ref_type:String"=>8010,
	// "master_branch:String"=>6724, "description:String"=>3701, "pusher_type:String"=>8010,
	// "pull_request:Hash"=>4475, "ref:NilClass"=>2124, "description:NilClass"=>3023,
	// "number:Fixnum"=>2992, "forkee:Hash"=>1211, "pages:Array"=>370, "release:Hash"=>156,
	// "member:Hash"=>219}
	// {"push_id"=>10, "size"=>4, "distinct_size"=>4, "ref"=>110, "head"=>40, "before"=>40,
	// "commits"=>33215, "action"=>9, "issue"=>87776, "comment"=>177917, "ref_type"=>10,
	// "master_branch"=>34, "description"=>3222, "pusher_type"=>4, "pull_request"=>70565,
	// "number"=>5, "forkee"=>6880, "pages"=>855, "release"=>31206, "member"=>1040}
	// 48746
	// using exec_stmt (without select), because payload are per event_id.
	pl := ev.Payload
	lib.ExecSQLWithErr(
		con,
		"insert into gha_payloads("+
			"event_id, push_id, size, ref, head, befor, action, "+
			"issue_id, comment_id, ref_type, master_branch, "+
			"description, number, forkee_id, release_id, member_id"+
			") "+lib.NValues(16),
		lib.AnyArray{
			eventID,
			lib.IntOrNil(pl.PushID),
			lib.IntOrNil(pl.Size),
			lib.TruncStringOrNil(pl.Ref, 200),
			lib.StringOrNil(pl.Head),
			lib.StringOrNil(pl.Before),
			lib.StringOrNil(pl.Action),
			lib.IssueIDOrNil(pl.Issue),
			lib.CommentIDOrNil(pl.Comment),
			lib.StringOrNil(pl.RefType),
			lib.TruncStringOrNil(pl.MasterBranch, 200),
			lib.TruncStringOrNil(pl.Description, 0xffff),
			lib.IntOrNil(pl.Number),
			lib.ForkeeIDOrNil(pl.Forkee),
			lib.ReleaseIDOrNil(pl.Release),
			lib.ActorIDOrNil(pl.Member),
		}...,
	)

	// gha_commits
	// {"sha:String"=>23265, "author:Hash"=>23265, "message:String"=>23265,
	// "distinct:TrueClass"=>21789, "url:String"=>23265, "distinct:FalseClass"=>1476}
	// {"sha"=>40, "author"=>177, "message"=>19005, "distinct"=>5, "url"=>191}
	// author: {"name:String"=>23265, "email:String"=>23265} (only git username/email)
	// author: {"name"=>96, "email"=>95}
	// 23265
	commits := []lib.Commit{}
	if pl.Commits != nil {
		commits = *pl.Commits
	}
	for _, commit := range commits {
		sha := commit.SHA
		lib.ExecSQLWithErr(
			con,
			"insert into gha_commits("+
				"sha, event_id, author_name, message, is_distinct) "+lib.NValues(5),
			lib.AnyArray{
				sha,
				eventID,
				lib.TruncToBytes(commit.Author.Name, 160),
				lib.TruncToBytes(commit.Message, 0xffff), // FIXME: in gha2db.rb it was allowing null, while DB structure doesn not permit this
				commit.Distinct,
			}...,
		)
	}

	// TODO: continue
	return 1
}

// repoHit - are we interested in this org/repo ?
func repoHit(fullName string, forg, frepo map[string]bool) bool {
	if fullName == "" {
		return false
	}
	res := strings.Split(fullName, "/")
	org, repo := res[0], res[1]
	if len(forg) > 0 {
		if _, ok := forg[org]; !ok {
			return false
		}
	}
	if len(frepo) > 0 {
		if _, ok := frepo[repo]; !ok {
			return false
		}
	}
	return true
}

// parseJSON - parse signle GHA JSON event
func parseJSON(ctx Ctx, con *sql.DB, jsonStr []byte, dt time.Time, forg, frepo map[string]bool) (f int, e int) {
	var h lib.Event
	err := json.Unmarshal(jsonStr, &h)
	if err != nil {
		fmt.Printf("'%v'\n", string(jsonStr))
	}
	lib.FatalOnError(err)
	fullName := h.Repo.Name
	if repoHit(fullName, forg, frepo) {
		eid := h.ID
		if ctx.jsonOut {
			// We want to Unmarshal/Marshall ALL JSON data, regardless of what is defined in lib.Event
			pretty := lib.PrettyPrintJSON(jsonStr)
			ofn := fmt.Sprintf("jsons/%v_%v.json", dt.Unix(), eid)
			err = ioutil.WriteFile(ofn, pretty, 0644)
			lib.FatalOnError(err)
		}
		if ctx.dbOut {
			// FIXME: not needed
			// fmt.Printf("JSON:\n%v\n", string(lib.PrettyPrintJSON(jsonStr)))
			e = writeToDB(ctx, con, h)
		}
		if ctx.Debug >= 1 {
			fmt.Printf("Processed: '%v' event: %v\n", dt, eid)
		}
		f = 1
	}
	return
}

// getGHAJSON - This is a work for single go routine - 1 hour of GHA data
// Usually such JSON conatin about 15000 - 60000 singe GHA events
// Boolean channel `ch` is used to synchronize go routines
func getGHAJSON(ch chan bool, ctx Ctx, dt time.Time, forg map[string]bool, frepo map[string]bool) {
	fmt.Printf("Working on %v\n", dt)

	// Connect to Postgres DB
	con, err := lib.Conn()
	lib.FatalOnError(err)
	defer con.Close()

	fn := fmt.Sprintf(
		"http://data.githubarchive.org/%04d-%02d-%02d-%d.json.gz",
		dt.Year(), dt.Month(), dt.Day(), dt.Hour(),
	)

	// Get gzipped JSON array via HTTP
	response, err := http.Get(fn)
	lib.FatalOnError(err)
	defer response.Body.Close()

	// Decompress Gzipped response
	reader, err := gzip.NewReader(response.Body)
	lib.FatalOnError(err)
	fmt.Printf("Opened %s\n", fn)
	defer reader.Close()
	jsonsBytes, err := ioutil.ReadAll(reader)
	lib.FatalOnError(err)
	fmt.Printf("Decompressed %s\n", fn)

	// Split JSON array into separate JSONs
	jsonsArray := bytes.Split(jsonsBytes, []byte("\n"))
	fmt.Printf("Splitted %s, %d JSONs\n", fn, len(jsonsArray))

	// Process JSONs one by one
	n, f, e := 0, 0, 0
	for _, json := range jsonsArray {
		if len(json) < 1 {
			continue
		}
		fi, ei := parseJSON(ctx, con, json, dt, forg, frepo)
		n++
		f += fi
		e += ei
	}
	fmt.Printf(
		"Parsed: %s: %d JSONs, found %d matching, events %d\n",
		fn, n, f, e,
	)
	if ch != nil {
		ch <- true
	}
}

// gha2db - main work horse
func gha2db(args []string) {
	// Environment context parse
	var ctx Ctx
	ctx.jsonOut = os.Getenv("GHA2DB_JSON") != ""
	ctx.dbOut = os.Getenv("GHA2DB_NODB") == ""
	if os.Getenv("GHA2DB_DEBUG") == "" {
		ctx.Debug = 0
	} else {
		debugLevel, err := strconv.Atoi(os.Getenv("GHA2DB_DEBUG"))
		lib.FatalOnError(err)
		ctx.Debug = debugLevel
	}

	hourFrom, err := strconv.Atoi(args[1])
	lib.FatalOnError(err)
	dFrom, err := time.Parse(
		time.RFC3339,
		fmt.Sprintf("%sT%02d:00:00+00:00", args[0], hourFrom),
	)
	lib.FatalOnError(err)

	hourTo, err := strconv.Atoi(args[3])
	lib.FatalOnError(err)
	dTo, err := time.Parse(
		time.RFC3339,
		fmt.Sprintf("%sT%02d:00:00+00:00", args[2], hourTo),
	)
	lib.FatalOnError(err)

	// Strip function to be used by MapString
	stripFunc := func(x string) string { return strings.TrimSpace(x) }

	// Stripping whitespace from org and repo params
	var org map[string]bool
	if len(args) >= 5 {
		org = lib.StringsMapToSet(
			stripFunc,
			strings.Split(args[4], ","),
		)
	}

	var repo map[string]bool
	if len(args) >= 6 {
		repo = lib.StringsMapToSet(
			stripFunc,
			strings.Split(args[5], ","),
		)
	}

	// Get number of CPUs available
	thrN := lib.GetThreadsNum()
	fmt.Printf(
		"Running (%v CPUs): %v - %v %v %v\n",
		thrN, dFrom, dTo,
		strings.Join(lib.StringsSetKeys(org), "+"),
		strings.Join(lib.StringsSetKeys(repo), "+"),
	)

	dt := dFrom
	if thrN > 1 {
		chanPool := []chan bool{}
		for dt.Before(dTo) || dt.Equal(dTo) {
			ch := make(chan bool)
			chanPool = append(chanPool, ch)
			go getGHAJSON(ch, ctx, dt, org, repo)
			dt = dt.Add(time.Hour)
			if len(chanPool) == thrN {
				ch = chanPool[0]
				<-ch
				chanPool = chanPool[1:]
			}
		}
		fmt.Printf("Final threads join\n")
		for _, ch := range chanPool {
			<-ch
		}
	} else {
		fmt.Printf("Using single threaded version\n")
		for dt.Before(dTo) || dt.Equal(dTo) {
			getGHAJSON(nil, ctx, dt, org, repo)
			dt = dt.Add(time.Hour)
		}
	}

	fmt.Printf("All done.\n")
}

func main() {
	// Required args
	if len(os.Args) < 5 {
		fmt.Printf(
			"Arguments required: date_from_YYYY-MM-DD hour_from_HH date_to_YYYY-MM-DD hour_to_HH " +
				"['org1,org2,...,orgN' ['repo1,repo2,...,repoN']]\n",
		)
		os.Exit(1)
	}
	gha2db(os.Args[1:])
}
