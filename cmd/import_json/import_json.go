package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"time"

	_ "github.com/mattn/go-sqlite3"

	lib "devstats"
)

// Dashboard stores main dashoard keys title and uid
type dashboard struct {
	Title string `json:"title"`
	UID   string `json:"uid"`
}

// importJsons uses sqlFile database to update list of JSONs
func importJsons(sqlFile string, jsons []string) {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Make DB backup:
	contents, err := ioutil.ReadFile(sqlFile)
	lib.FatalOnError(err)
	lib.FatalOnError(ioutil.WriteFile(
		fmt.Sprintf("%s.%v", sqlFile, time.Now().UnixNano()),
		contents,
		0644,
	))

	// Connect to SQLite3
	db, err := sql.Open("sqlite3", sqlFile)
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(db.Close()) }()
	var (
		dash  dashboard
		dash2 dashboard
		data  string
		id    int
	)

	// Process JSONs
	for i, j := range jsons {
		lib.Printf("Importing %d json: %s\n", i+1, j)
		// Read JSON
		bytes, err := ioutil.ReadFile(j)
		lib.FatalOnError(err)
		sBytes := string(bytes)
		// Get title & uid
		err = json.Unmarshal(bytes, &dash)
		lib.FatalOnError(err)
		// Get original JSON
		stmt, err := db.Prepare("select id, data from dashboard where title = ?")
		lib.FatalOnError(err)
		defer func() { lib.FatalOnError(stmt.Close()) }()
		err = stmt.QueryRow(dash.Title).Scan(&id, &data)
		lib.FatalOnError(err)
		// Save JSON from DB
		lib.FatalOnError(ioutil.WriteFile(j+".was", lib.PrettyPrintJSON([]byte(data)), 0644))
		// Check UIDs
		err = json.Unmarshal([]byte(data), &dash2)
		lib.FatalOnError(err)
		if dash.UID != dash2.UID {
			lib.Printf("UID mismatch, json value: %s, database value: %s, skipping\n", dash.UID, dash2.UID)
			continue
		}
		// Update JSON inside database
		_, err = db.Exec("update dashboard set data = ? where id = ?", sBytes, id)
		lib.FatalOnError(err)
		if ctx.Debug > 0 {
			lib.Printf("Updated:\n%s\nTo:\n%s\n", data, sBytes)
		}
	}
}

func main() {
	dtStart := time.Now()
	if len(os.Args) < 3 {
		lib.Printf("Required sql file name and list of jsons to import.\n")
		os.Exit(1)
	}
	importJsons(os.Args[1], os.Args[2:])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
