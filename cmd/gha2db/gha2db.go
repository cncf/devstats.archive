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

func writeToDb(ctx Ctx, con *sql.DB, ev lib.Event) int {
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
	fmt.Printf("eid=%v, exists=%v\n", eventID, exists)
	if exists == 1 {
		return 0
	}
	args := []interface{}{
		eventID,
		ev.Type,
		ev.Actor.ID,
		ev.Repo.ID,
		ev.Public,
		ev.CreatedAt,
		ev.Actor.Login,
		ev.Repo.Name,
	}
	if ev.Org == nil {
		args = append(args, ev.Org.ID)
	} else {
		args = append(args, nil)
	}
	lib.ExecSQLWithErr(
		con,
		"insert into gha_events("+
			"id, type, actor_id, repo_id, public, created_at, "+
			"actor_login, repo_name, org_id) "+lib.NValues(9),
		args...,
	)
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
			var full interface{}
			err := json.Unmarshal(jsonStr, &full)
			lib.FatalOnError(err)
			data, err := json.MarshalIndent(full, "", "  ")
			lib.FatalOnError(err)
			ofn := fmt.Sprintf("jsons/%v_%v.json", dt.Unix(), eid)
			err = ioutil.WriteFile(ofn, []byte(data), 0644)
			lib.FatalOnError(err)
		}
		if ctx.dbOut {
			e = writeToDb(ctx, con, h)
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
