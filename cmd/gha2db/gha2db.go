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

// parseJSON - Parse signle GHA JSON event
func parseJSON(con *sql.DB, jsonStr []byte, dt time.Time, forg []string, frepo []string) (f int, e int) {
	var h lib.GHA
	if len(jsonStr) < 1 {
		return
	}
	err := json.Unmarshal(jsonStr, &h)
	if err != nil {
		fmt.Printf("'%v'\n", jsonStr)
	}
	lib.FatalOnError(err)
  fmt.Printf("repo: %v\n", h.Repo.Name)
	/*
	  h = JSON.parse json
	  full_name = h['repo']['name']
	  if repo_hit(full_name, forg, frepo)
	    eid = h['id']
	    if $json_out
	      prt = JSON.pretty_generate(h)
	      ofn = "jsons/#{dt.to_i}_#{eid}.json"
	      File.write ofn, prt
	    end
	    if $db_out
	      $ev[Thread.current.object_id] = h
	      e = write_to_pg(con, h)
	      $ev.delete(Thread.current.object_id)
	    end
	    puts "Processed: '#{dt}' event: #{eid}" if $debug >= 1
	    f = 1
	  end
	  [f, e]
	*/
	return
}

// getGHAJSON - This is a work for single go routine - 1 hour of GHA data
// Usually such JSON conatin about 15000 - 60000 singe GHA events
// Boolean channel `ch` is used to synchronize go routines
func getGHAJSON(ch chan bool, dt time.Time, forg []string, frepo []string) {
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
		fi, ei := parseJSON(con, json, dt, forg, frepo)
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
	org := []string{}
	if len(args) >= 5 {
		org = lib.StringsMap(
			stripFunc,
			strings.Split(args[4], ","),
		)
	}

	repo := []string{}
	if len(args) >= 6 {
		repo = lib.StringsMap(
			stripFunc,
			strings.Split(args[5], ","),
		)
	}

	// Get number of CPUs available
	thrN := lib.GetThreadsNum()
	fmt.Printf("Running (%v CPUs): %v - %v %v %v\n", thrN, dFrom, dTo, strings.Join(org, "+"), strings.Join(repo, "+"))

	dt := dFrom
	if thrN > 1 {
		chanPool := []chan bool{}
		for dt.Before(dTo) || dt.Equal(dTo) {
			ch := make(chan bool)
			chanPool = append(chanPool, ch)
			go getGHAJSON(ch, dt, org, repo)
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
			getGHAJSON(nil, dt, org, repo)
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
