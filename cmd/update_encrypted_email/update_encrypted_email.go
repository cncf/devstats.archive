package main

import (
	"bytes"
	"compress/gzip"
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	lib "devstats"
)

// Write GHA entire event (in old pre 2015 format) into Postgres DB
func writeToDBOldFmt(db *sql.DB, ctx *lib.Ctx, eventID string, ev *lib.EventOld, shas map[string]string) int {
	// To handle GDPR
	maybeHide := lib.MaybeHideFunc(shas)

	// Pre 2015 Payload
	pl := ev.Payload
	if pl == nil {
		return 0
	}

	// SHAs - commits
	if pl.SHAs != nil {
		commits := *pl.SHAs
		for _, comm := range commits {
			commit, ok := comm.([]interface{})
			if !ok {
				lib.Fatalf("comm is not []interface{}: %+v", comm)
			}
			sha, ok := commit[0].(string)
			if !ok {
				lib.Fatalf("commit[0] is not string: %+v", commit[0])
			}
			res := lib.ExecSQLWithErr(
				db,
				ctx,
				fmt.Sprintf(
					//"update gha_commits set encrypted_email = %s where sha = %s and event_id = %s and author_name = %s",
					"update gha_commits set encrypted_email = %s where sha = %s and event_id = %s",
					lib.NValue(1),
					lib.NValue(2),
					lib.NValue(3),
					//lib.NValue(4),
				),
				lib.AnyArray{
					lib.TruncToBytes(commit[1].(string), 160),
					sha,
					eventID,
					//maybeHide(lib.TruncToBytes(commit[3].(string), 160)),
				}...,
			)
			aff, err := res.RowsAffected()
			lib.FatalOnError(err)
			if aff < 1 && ctx.Debug > 0 {
				lib.Printf("Warning: commit not found sha=%s, event_id=%s, name: %s\n", sha, eventID, maybeHide(lib.TruncToBytes(commit[3].(string), 160)))
				return -1
			}
		}
		return 1
	}

	return 0
}

// Write entire GHA event (in a new 2015+ format) into Postgres DB
func writeToDB(db *sql.DB, ctx *lib.Ctx, ev *lib.Event, shas map[string]string) int {
	// To handle GDPR
	maybeHide := lib.MaybeHideFunc(shas)

	// Event ID
	eventID := ev.ID

	// Payload
	pl := ev.Payload

	commits := []lib.Commit{}
	if pl.Commits != nil {
		commits = *pl.Commits
	}
	for _, commit := range commits {
		sha := commit.SHA
		res := lib.ExecSQLWithErr(
			db,
			ctx,
			fmt.Sprintf(
				//"update gha_commits set encrypted_email = %s where sha = %s and event_id = %s and author_name = %s",
				"update gha_commits set encrypted_email = %s where sha = %s and event_id = %s",
				lib.NValue(1),
				lib.NValue(2),
				lib.NValue(3),
				//lib.NValue(4),
			),
			lib.AnyArray{
				lib.TruncToBytes(commit.Author.Email, 160),
				sha,
				eventID,
				//maybeHide(lib.TruncToBytes(commit.Author.Name, 160)),
			}...,
		)
		aff, err := res.RowsAffected()
		lib.FatalOnError(err)
		if aff < 1 && ctx.Debug > 0 {
			lib.Printf("Warning: commit not found sha=%s, event_id=%s, name: %s\n", sha, eventID, maybeHide(lib.TruncToBytes(commit.Author.Name, 160)))
			return -1
		}
		return 1
	}

	return 0
}

// parseJSON - parse signle GHA JSON event
func parseJSON(con *sql.DB, ctx *lib.Ctx, idx, njsons int, jsonStr []byte, dt time.Time, forg, frepo map[string]struct{}, shas map[string]string) (f int, e int) {
	var (
		h         lib.Event
		hOld      lib.EventOld
		err       error
		fullName  string
		eid       string
		actorName string
	)
	if ctx.OldFormat {
		err = json.Unmarshal(jsonStr, &hOld)
	} else {
		err = json.Unmarshal(jsonStr, &h)
	}
	// jsonStr = bytes.Replace(jsonStr, []byte("\x00"), []byte(""), -1)
	if err != nil {
		ofn := fmt.Sprintf("jsons/error_%v-%d-%d.json", lib.ToGHADate(dt), idx+1, njsons)
		lib.FatalOnError(ioutil.WriteFile(ofn, jsonStr, 0644))
		lib.Printf("%v: Cannot unmarshal:\n%s\n%v\n", dt, string(jsonStr), err)
		fmt.Fprintf(os.Stderr, "%v: Cannot unmarshal:\n%s\n%v\n", dt, string(jsonStr), err)
		if ctx.AllowBrokenJSON {
			return
		}
		pretty := lib.PrettyPrintJSON(jsonStr)
		lib.Printf("%v: JSON Unmarshal failed for:\n'%v'\n", dt, string(pretty))
		fmt.Fprintf(os.Stderr, "%v: JSON Unmarshal failed for:\n'%v'\n", dt, string(pretty))
	}
	lib.FatalOnError(err)
	if ctx.OldFormat {
		fullName = lib.MakeOldRepoName(&hOld.Repository)
		actorName = hOld.Actor
	} else {
		fullName = h.Repo.Name
		actorName = h.Actor.Login
	}
	if lib.RepoHit(ctx, fullName, forg, frepo) && lib.ActorHit(ctx, actorName) {
		if ctx.OldFormat {
			eid = fmt.Sprintf("%v", lib.HashStrings([]string{hOld.Type, hOld.Actor, hOld.Repository.Name, lib.ToYMDHMSDate(hOld.CreatedAt)}))
		} else {
			eid = h.ID
		}
		if ctx.JSONOut {
			// We want to Unmarshal/Marshall ALL JSON data, regardless of what is defined in lib.Event
			pretty := lib.PrettyPrintJSON(jsonStr)
			ofn := fmt.Sprintf("jsons/%v_%v.json", dt.Unix(), eid)
			lib.FatalOnError(ioutil.WriteFile(ofn, pretty, 0644))
		}
		if ctx.DBOut {
			if ctx.OldFormat {
				e = writeToDBOldFmt(con, ctx, eid, &hOld, shas)
			} else {
				e = writeToDB(con, ctx, &h, shas)
			}
		}
		if ctx.Debug >= 1 {
			lib.Printf("Processed: '%v' event: %v\n", dt, eid)
		}
		f = 1
	}
	return
}

// getGHAJSON - This is a work for single go routine - 1 hour of GHA data
// Usually such JSON conatin about 15000 - 60000 singe GHA events
// Boolean channel `ch` is used to synchronize go routines
func getGHAJSON(ch chan bool, ctx *lib.Ctx, dt time.Time, forg map[string]struct{}, frepo map[string]struct{}, shas map[string]string) {
	lib.Printf("Working on %v\n", dt)

	// Connect to Postgres DB
	con := lib.PgConn(ctx)
	defer func() { lib.FatalOnError(con.Close()) }()

	fn := fmt.Sprintf("http://data.gharchive.org/%s.json.gz", lib.ToGHADate(dt))

	// Get gzipped JSON array via HTTP
	response, err := http.Get(fn)
	if err != nil {
		lib.Printf("%v: Error http.Get:\n%v\n", dt, err)
		fmt.Fprintf(os.Stderr, "%v: Error http.Get:\n%v\n", dt, err)
	}
	lib.FatalOnError(err)
	defer func() { _ = response.Body.Close() }()

	// Decompress Gzipped response
	reader, err := gzip.NewReader(response.Body)
	//lib.FatalOnError(err)
	if err != nil {
		lib.Printf("%v: No data yet, gzip reader:\n%v\n", dt, err)
		fmt.Fprintf(os.Stderr, "%v: No data yet, gzip reader:\n%v\n", dt, err)
		if ch != nil {
			ch <- true
		}
		return
	}
	lib.Printf("Opened %s\n", fn)
	defer func() { _ = reader.Close() }()

	jsonsBytes, err := ioutil.ReadAll(reader)
	//lib.FatalOnError(err)
	if err != nil {
		lib.Printf("%v: Error (no data yet, ioutil readall):\n%v\n", dt, err)
		fmt.Fprintf(os.Stderr, "%v: Error (no data yet, ioutil readall):\n%v\n", dt, err)
		if ch != nil {
			ch <- true
		}
		return
	}
	lib.Printf("Decompressed %s\n", fn)

	// Split JSON array into separate JSONs
	jsonsArray := bytes.Split(jsonsBytes, []byte("\n"))
	lib.Printf("Split %s, %d JSONs\n", fn, len(jsonsArray))

	// Process JSONs one by one
	n, f, e := 0, 0, 0
	njsons := len(jsonsArray)
	for i, json := range jsonsArray {
		if len(json) < 1 {
			continue
		}
		fi, ei := parseJSON(con, ctx, i, njsons, json, dt, forg, frepo, shas)
		n++
		f += fi
		e += ei
	}
	lib.Printf(
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
	var (
		ctx      lib.Ctx
		err      error
		hourFrom int
		hourTo   int
		dFrom    time.Time
		dTo      time.Time
	)
	ctx.Init()

	// Current date
	now := time.Now()
	startD, startH, endD, endH := args[0], args[1], args[2], args[3]

	// Parse from day & hour
	if strings.ToLower(startH) == lib.Now {
		hourFrom = now.Hour()
	} else {
		hourFrom, err = strconv.Atoi(startH)
		lib.FatalOnError(err)
	}

	if strings.ToLower(startD) == lib.Today {
		dFrom = lib.DayStart(now).Add(time.Duration(hourFrom) * time.Hour)
	} else {
		dFrom, err = time.Parse(
			time.RFC3339,
			fmt.Sprintf("%sT%02d:00:00+00:00", startD, hourFrom),
		)
		lib.FatalOnError(err)
	}

	// Parse to day & hour
	if strings.ToLower(endH) == lib.Now {
		hourTo = now.Hour()
	} else {
		hourTo, err = strconv.Atoi(endH)
		lib.FatalOnError(err)
	}

	if strings.ToLower(endD) == lib.Today {
		dTo = lib.DayStart(now).Add(time.Duration(hourTo) * time.Hour)
	} else {
		dTo, err = time.Parse(
			time.RFC3339,
			fmt.Sprintf("%sT%02d:00:00+00:00", endD, hourTo),
		)
		lib.FatalOnError(err)
	}

	// Strip function to be used by MapString
	stripFunc := func(x string) string { return strings.TrimSpace(x) }

	// Stripping whitespace from org and repo params
	var org map[string]struct{}
	if len(args) >= 5 {
		org = lib.StringsMapToSet(
			stripFunc,
			strings.Split(args[4], ","),
		)
	}

	var repo map[string]struct{}
	if len(args) >= 6 {
		repo = lib.StringsMapToSet(
			stripFunc,
			strings.Split(args[5], ","),
		)
	}

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)
	lib.Printf(
		"gha2db.go: Running (%v CPUs): %v - %v %v %v\n",
		thrN, dFrom, dTo,
		strings.Join(lib.StringsSetKeys(org), "+"),
		strings.Join(lib.StringsSetKeys(repo), "+"),
	)

	// GDPR data hiding
	shaMap := lib.GetHidden(lib.HideCfgFile)

	dt := dFrom
	if thrN > 1 {
		ch := make(chan bool)
		nThreads := 0
		for dt.Before(dTo) || dt.Equal(dTo) {
			go getGHAJSON(ch, &ctx, dt, org, repo, shaMap)
			dt = dt.Add(time.Hour)
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
		for dt.Before(dTo) || dt.Equal(dTo) {
			getGHAJSON(nil, &ctx, dt, org, repo, shaMap)
			dt = dt.Add(time.Hour)
		}
	}
	// Finished
	lib.Printf("All done.\n")
}

func main() {
	dtStart := time.Now()
	// Required args
	if len(os.Args) < 5 {
		lib.Printf(
			"Arguments required: date_from_YYYY-MM-DD hour_from_HH date_to_YYYY-MM-DD hour_to_HH " +
				"['org1,org2,...,orgN' ['repo1,repo2,...,repoN']]\n",
		)
		os.Exit(1)
	}
	gha2db(os.Args[1:])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
