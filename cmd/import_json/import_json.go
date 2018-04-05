package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"strings"
	"time"

	_ "github.com/mattn/go-sqlite3"

	lib "devstats"
)

// Dashboard stores main dashoard keys title and uid
type dashboard struct {
	Title string `json:"title"`
	UID   string `json:"uid"`
}

// outputJsons uses dbFile database to dump all dashboards as JSONs
func outputJsons(dbFile string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Connect to SQLite3
	db, err := sql.Open("sqlite3", dbFile)
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(db.Close()) }()

	// Get all dashboards
	rows, err := db.Query("select slug, title, data from dashboard")
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(rows.Close()) }()
	var (
		slug  string
		title string
		data  string
	)
	// Save all of them as sqlite/slug[i].json for i=0..n
	for rows.Next() {
		err = rows.Scan(&slug, &title, &data)
		lib.FatalOnError(err)
		fn := "sqlite/" + slug + ".json"
		lib.FatalOnError(ioutil.WriteFile(fn, lib.PrettyPrintJSON([]byte(data)), 0644))
		lib.Printf("Written '%s' to %s\n", title, fn)
	}
	err = rows.Err()
	lib.FatalOnError(err)
}

// importJsons uses dbFile database to update list of JSONs
// each json can be either:
// 1) "filename.json"
// a) it will search for a SQLite dashboard with "title" the same as JSON's "title" property
// b) it will check if JSON's "uid" is the same as SQLite's dashboard JSON's "uid"
// c) it will udpate SQLite's dashboards "data" with new JSON
// d) SQLite's dashboard "title" and "slug" won't be changed
// 2) "filename.json;old title;new slug"
// a) it will search for a SQLite dashboard with "title" = "old title"
// b) it will check if JSON's "uid" is the same as SQLite's dashboard JSON's "uid"
// c) it will udpate SQLite's "data" with new JSON
// d) it will update SQLite's dashboard "title" with "title" property from filename.json
// e) it will update SQLite's dashboard "slug" = "new slug"
func importJsons(dbFile string, jsons []string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// DB backup func, executed when anything is updated
	backedUp := false
	contents, err := lib.ReadFile(&ctx, dbFile)
	lib.FatalOnError(err)
	backupFunc := func() {
		bfn := fmt.Sprintf("%s.%v", dbFile, time.Now().UnixNano())
		lib.FatalOnError(ioutil.WriteFile(bfn, contents, 0644))
		lib.Printf("Original db file backed up as' %s'\n", bfn)
	}

	// Connect to SQLite3
	db, err := sql.Open("sqlite3", dbFile)
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(db.Close()) }()
	var (
		dash  dashboard
		dash2 dashboard
		data  string
		id    int
		slug  string
	)

	// Process JSONs
	for i, jdata := range jsons {
		// each jdata can be: "filename.json" or "filename.json;old title;new slug"
		ary := strings.Split(jdata, ";")
		j := ary[0]
		l := len(ary)
		if l != 1 && l != 3 {
			lib.Fatalf("you need to provide jsons either as 'filename.json' or as 'fn.json;old title;new slug'")
		}

		// Read JSON: get title & uid
		lib.Printf("Importing #%d json: %s (%v)\n", i+1, j, ary)
		bytes, err := lib.ReadFile(&ctx, j)
		lib.FatalOnError(err)
		sBytes := string(bytes)
		err = json.Unmarshal(bytes, &dash)
		lib.FatalOnError(err)

		// Either use dashboard title from JSON or use "old title" provided from command line
		dashTitle := dash.Title
		if len(ary) > 1 {
			dashTitle = ary[1]
		}

		// Get original id, JSON, slug
		rows, err := db.Query("select id, data, slug from dashboard where title = ?", dashTitle)
		lib.FatalOnError(err)
		defer func() { lib.FatalOnError(rows.Close()) }()
		got := false
		for rows.Next() {
			err = rows.Scan(&id, &data, &slug)
			lib.FatalOnError(err)
			got = true
		}
		err = rows.Err()
		lib.FatalOnError(err)
		if !got {
			lib.Fatalf("dashboard titled: '%s' not found", dashTitle)
		}

		// And save JSON from DB
		lib.FatalOnError(ioutil.WriteFile(j+".was", lib.PrettyPrintJSON([]byte(data)), 0644))

		// Check UIDs
		err = json.Unmarshal([]byte(data), &dash2)
		lib.FatalOnError(err)
		if dash.UID != dash2.UID {
			lib.Printf("UID mismatch, json value: %s, database value: %s, skipping\n", dash.UID, dash2.UID)
			continue
		}

		// Update JSON inside database
		dashSlug := slug
		if len(ary) > 2 {
			dashSlug = ary[2]
		}
		_, err = db.Exec(
			"update dashboard set title = ?, slug = ?, data = ? where id = ?",
			dash.Title, dashSlug, sBytes, id,
		)
		lib.FatalOnError(err)
		if ctx.Debug > 0 {
			lib.Printf("Updated (title: '%s' -> '%s', slug: '%s' -> '%s'):\n%s\nTo:\n%s\n", dashTitle, dash.Title, slug, dashSlug, data, sBytes)
		} else {
			lib.Printf("Updated dashboard: title: '%s' -> '%s', slug: '%s' -> '%s'\n", dashTitle, dash.Title, slug, dashSlug)
		}

		//Something changed, backup original db file
		if !backedUp {
			backupFunc()
			backedUp = true
		}
	}
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 2 {
		lib.Printf("%s: required args: grafana.db file name and list(*) of jsons to import.\n", os.Args[0])
		lib.Printf("%s: if only db file name given, it will output all dashboards to jsons\n", os.Args[0])
		lib.Printf("%s: each list item can be either filename.json name or 'fn.json;old title;new slug'\n", os.Args[0])
		os.Exit(1)
	}
	if len(os.Args) > 2 {
		importJsons(os.Args[1], os.Args[2:])
	} else {
		outputJsons(os.Args[1])
	}
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
