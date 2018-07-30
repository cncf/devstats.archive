package main

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
	"sort"
	"strconv"
	"strings"
	"time"

	_ "github.com/mattn/go-sqlite3"

	lib "devstats"
)

// dashboard stores main dashoard keys title and uid
type dashboard struct {
	Title string   `json:"title"`
	UID   string   `json:"uid"`
	Tags  []string `json:"tags"`
}

// dashboardData keeps all dashboard data & metadata
type dashboardData struct {
	dash  dashboard
	id    int
	title string
	slug  string
	data  string
	fn    string
	uid   string
}

// String for dashboardData - skip displaying long JSON data
func (dd dashboardData) String() string {
	return fmt.Sprintf(
		"{dash:'%+v', id:%d, title:'%s', slug:'%s', data:len:%d, fn:'%s'}",
		dd.dash, dd.id, dd.title, dd.slug, len(dd.data), dd.fn,
	)
}

// sqliteQueryOut outputs SQLite query info
func sqliteQueryOut(query string, args ...interface{}) {
	if len(args) > 0 {
		lib.Printf("%+v\n", args)
	}
	lib.Printf("%s\n", query)
}

// sqliteQuery execute SQLite query with eventual logging output
func sqliteQuery(db *sql.DB, ctx *lib.Ctx, query string, args ...interface{}) (*sql.Rows, error) {
	if ctx.QOut {
		sqliteQueryOut(query, args...)
	}
	return db.Query(query, args...)
}

// sqliteExec SQLite exec call with eventual logging output
func sqliteExec(db *sql.DB, ctx *lib.Ctx, exec string, args ...interface{}) (sql.Result, error) {
	if ctx.QOut {
		sqliteQueryOut(exec, args...)
	}
	return db.Exec(exec, args...)
}

// updateTags make JSON and SQLite tags match each other
func updateTags(db *sql.DB, ctx *lib.Ctx, did int, jsonTags []string, info string) bool {
	// Get SQLite DB dashboard tags
	rows, err := sqliteQuery(
		db,
		ctx,
		"select term from dashboard_tag where dashboard_id = ? order by term asc",
		did,
	)
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(rows.Close()) }()
	tag := ""
	dbTags := []string{}
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&tag))
		dbTags = append(dbTags, tag)
	}
	lib.FatalOnError(rows.Err())

	// Sort jsonTags
	sort.Strings(jsonTags)
	sJSONTags := strings.Join(jsonTags, ",")
	sDBTags := strings.Join(dbTags, ",")
	// If the same tag set, return false - meaning no update was needed
	if sJSONTags == sDBTags {
		return false
	}

	// Now sync tags
	allMap := make(map[string]struct{})
	dbMap := make(map[string]struct{})
	jsonMap := make(map[string]struct{})
	for _, tag := range jsonTags {
		jsonMap[tag] = struct{}{}
		allMap[tag] = struct{}{}
	}
	for _, tag := range dbTags {
		dbMap[tag] = struct{}{}
		allMap[tag] = struct{}{}
	}
	nI := 0
	nD := 0
	for tag := range allMap {
		_, j := jsonMap[tag]
		_, d := dbMap[tag]
		// We have it in JSOn but not in DB, insert
		if j && !d {
			_, err = sqliteExec(
				db,
				ctx,
				"insert into dashboard_tag(dashboard_id, term) values(?, ?)",
				did, tag,
			)
			lib.FatalOnError(err)
			if ctx.Debug > 0 {
				lib.Printf(
					"Updating dashboard '%s' id: %d, '%v' -> '%v', inserted '%s' tag\n",
					info, did, sDBTags, sJSONTags, tag,
				)
			}
			nI++
		}
		// We have it in DB but not in JSON, delete
		if !j && d {
			_, err = sqliteExec(
				db,
				ctx,
				"delete from dashboard_tag where dashboard_id = ? and term = ?",
				did, tag,
			)
			lib.FatalOnError(err)
			if ctx.Debug > 0 {
				lib.Printf(
					"Updating dashboard '%s' id: %d, '%v' -> '%v', deleted '%s' tag\n",
					info, did, sDBTags, sJSONTags, tag,
				)
			}
			nD++
		}
	}
	lib.Printf(
		"Updated dashboard tags '%s' id: %d, '%v' -> '%v', added: %d, removed: %d\n",
		info, did, sDBTags, sJSONTags, nI, nD,
	)
	return true
}

// deleteUids opens dbFile and delete all dashboards with given uids
func deleteUids(ctx *lib.Ctx, dbFile string, uids []string) {
	// Connect to SQLite3
	db, err := sql.Open("sqlite3", dbFile)
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(db.Close()) }()

	// Iterate uids
	for _, uid := range uids {
		rows, err := sqliteQuery(db, ctx, "select id from dashboard where uid = ?", uid)
		lib.FatalOnError(err)
		defer func() { lib.FatalOnError(rows.Close()) }()
		id := -1
		for rows.Next() {
			lib.FatalOnError(rows.Scan(&id))
		}
		lib.FatalOnError(rows.Err())
		if id < 0 {
			lib.Printf("Dashboard with uid=%s not found, skipping\n", uid)
			continue
		}
		_, err = sqliteExec(db, ctx, "delete from dashboard_tag where dashboard_id = ?", id)
		lib.FatalOnError(err)
		_, err = sqliteExec(db, ctx, "delete from dashboard where id = ?", id)
		lib.FatalOnError(err)
		lib.Printf("Deleted dashboard with uid %s\n", uid)
	}
}

// exportJsons uses dbFile database to dump all dashboards as JSONs
func exportJsons(ctx *lib.Ctx, dbFile string) {
	// Connect to SQLite3
	db, err := sql.Open("sqlite3", dbFile)
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(db.Close()) }()

	// Get all dashboards
	rows, err := sqliteQuery(db, ctx, "select slug, title, data from dashboard")
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(rows.Close()) }()
	var (
		slug  string
		title string
		data  string
	)
	// Save all of them as sqlite/slug[i].json for i=0..n
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&slug, &title, &data))
		fn := "sqlite/" + slug + ".json"
		lib.FatalOnError(ioutil.WriteFile(fn, lib.PrettyPrintJSON([]byte(data)), 0644))
		lib.Printf("Written '%s' to %s\n", title, fn)
	}
	lib.FatalOnError(rows.Err())
}

// insertDashboard inserts new dashboard into SQLite database
func insertDashboard(db *sql.DB, ctx *lib.Ctx, dd *dashboardData) {
	dd.uid = dd.dash.UID
	dd.title = dd.dash.Title
	dd.slug = lib.Slugify(dd.title)

	// Insert new dashboard
	_, err := sqliteExec(
		db,
		ctx,
		"insert into dashboard(version, slug, title, data, "+
			"org_id, created, updated, created_by, updated_by, "+
			"gnet_id, plugin_id, folder_id, is_folder, has_acl, uid) "+
			"values(1, ?, ?, ?, 1, ?, ?, 1, 1, 0, '', 0, 0, 0, ?)",
		dd.slug, dd.title, dd.data, time.Now(), time.Now(), dd.uid,
	)
	lib.FatalOnError(err)
	rows, err := sqliteQuery(db, ctx, "select max(id) from dashboard")
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(rows.Close()) }()
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&dd.id))
	}
	lib.FatalOnError(rows.Err())
	lib.Printf("Inserted dashboard: id=%d (uid=%s, title=%s, slug=%s)\n", dd.id, dd.uid, dd.title, dd.slug)
	updated := updateTags(db, ctx, dd.id, dd.dash.Tags, dd.dash.UID+" "+dd.dash.Title)
	if len(dd.dash.Tags) > 0 && !updated {
		lib.Fatalf("should add new tags for %+v", dd)
	}
}

// importJsons uses dbFile database to update list of JSONs
// It first loads all dashboards titles, slugs, ids and JSONs
// Then it parses all JSONs to get each dashboards UID
// Then it processes all JSONs provided, parses them, and gets each JSONs uid and title
// Each uid from JSON list must be unique
// Then for all JSON titles it creates slugs 'Name of Dashboard' -> 'name-of-dashboard'
// Finally it attempts to update SQLite database's data, tile, slug values by matching using UID
func importJsons(ctx *lib.Ctx, dbFile string, jsons []string) {
	// DB backup func, executed when anything is updated
	backedUp := false
	contents, err := lib.ReadFile(ctx, dbFile)
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

	// Load and parse all dashboards JSONs
	// Will keep uid --> sqlite dashboard data map
	dbMap := make(map[string]dashboardData)
	rows, err := sqliteQuery(db, ctx, "select id, data, title, slug, uid from dashboard")
	lib.FatalOnError(err)
	defer func() { lib.FatalOnError(rows.Close()) }()
	for rows.Next() {
		var dd dashboardData
		lib.FatalOnError(rows.Scan(&dd.id, &dd.data, &dd.title, &dd.slug, &dd.uid))
		lib.FatalOnError(json.Unmarshal([]byte(dd.data), &dd.dash))
		if dd.title != dd.dash.Title {
			lib.Printf("SQLite internal inconsistency (title): %s != %s: %+v, using value from dashboard table, not from JSON\n", dd.title, dd.dash.Title, dd)
			dd.dash.Title = dd.title
		}
		if dd.uid != dd.dash.UID {
			lib.Printf("SQLite internal inconsistency (uid): %s != %s: %+v, using value from dashboard table, not from JSON\n", dd.uid, dd.dash.UID, dd)
			dd.dash.UID = dd.uid
		}
		dd.data = string(lib.PrettyPrintJSON([]byte(dd.data)))
		dd.fn = "*" + dd.slug + ".json*"
		dbMap[dd.dash.UID] = dd
	}
	lib.FatalOnError(rows.Err())
	nDbMap := len(dbMap)

	// Now load & parse JSON arguments
	jsonMap := make(map[string]dashboardData)
	nIns := 0
	for _, j := range jsons {
		var dd dashboardData
		bytes, err := lib.ReadFile(ctx, j)
		lib.FatalOnError(err)
		lib.FatalOnError(json.Unmarshal(bytes, &dd.dash))
		dbDash, ok := dbMap[dd.dash.UID]
		if !ok {
			dd.data = string(lib.PrettyPrintJSON(bytes))
			dd.fn = j
			insertDashboard(db, ctx, &dd)
			if !backedUp {
				backupFunc()
				backedUp = true
			}
			nIns++
			continue
		}
		jsonDash, ok := jsonMap[dd.dash.UID]
		if ok {
			lib.Fatalf("%s: duplicate json uid, attempt to import %v, collision with %v", j, dd.dash, jsonDash.dash)
		}
		dd.data = string(lib.PrettyPrintJSON(bytes))
		dd.id = dbDash.id
		dd.uid = dd.dash.UID
		dd.title = dd.dash.Title
		dd.slug = lib.Slugify(dd.title)
		dd.fn = j
		jsonMap[dd.dash.UID] = dd
	}
	nJSONMap := len(jsonMap)

	// Now do updates
	nImp := 0
	for uid, dd := range jsonMap {
		ddWas := dbMap[uid]
		if ctx.Debug > 1 {
			lib.Printf("\n%+v\n%+v\n\n", dd.String(), ddWas.String())
		}
		// Update/check tags
		updated := updateTags(db, ctx, dd.id, dd.dash.Tags, dd.dash.UID+" "+dd.dash.Title)

		// Check if we actually need to update anything
		if ddWas.dash.Title == dd.dash.Title && ddWas.slug == dd.slug && ddWas.data == dd.data {
			if updated {
				if !backedUp {
					backupFunc()
					backedUp = true
				}
				nImp++
			}
			continue
		}
		// Update JSON inside database
		_, err = sqliteExec(
			db,
			ctx,
			"update dashboard set title = ?, slug = ?, data = ? where id = ?",
			dd.dash.Title, dd.slug, dd.data, dd.id,
		)
		lib.FatalOnError(err)

		// Info
		if ctx.Debug > 0 {
			lib.Printf(
				"%s: updated uid: %s: tags updated: %v\nnew: %+v\nold: %+v\n",
				dd.fn, uid, updated, dd, ddWas,
			)
		} else {
			lib.Printf(
				"%s: updated dashboard: uid: %s title: '%s' -> '%s', slug: '%s' -> '%s', tags: %v:%v (data %d -> %d bytes)\n",
				dd.fn, uid, ddWas.dash.Title, dd.dash.Title, ddWas.slug, dd.slug, updated, dd.dash.Tags, len(ddWas.data), len(dd.data),
			)
		}

		// And save JSON from DB
		lib.FatalOnError(ioutil.WriteFile(dd.fn+".was", []byte(ddWas.data), 0644))

		// Something changed, backup original db file
		if !backedUp {
			backupFunc()
			backedUp = true
		}
		nImp++
	}
	lib.Printf(
		"SQLite DB has %d dashboards, there were %d JSONs to import, updated %d, created %d\n",
		nDbMap, nJSONMap+nIns, nImp, nIns)
}

func main() {
	dtStart := time.Now()
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	if len(os.Args) < 2 {
		lib.Printf("Required args: grafana.db file name and list(*) of jsons to import.\n")
		lib.Printf("If only db file name given, it will output all dashboards to jsons\n")
		lib.Printf("It will import JSONs by matching their internal uid with SQLite database\n")
		lib.Printf("If DB name given and single argument with comman separated uids - dashboards with those uids will be removed\n")
		os.Exit(1)
	}
	del := false
	uids := []string{}
	if len(os.Args) == 3 {
		ary := strings.Split(os.Args[2], ",")
		brk := false
		for _, item := range ary {
			_, err := strconv.Atoi(item)
			if err != nil {
				brk = true
				break
			}
			uids = append(uids, item)
		}
		if !brk {
			del = true
		}
	}
	if del {
		deleteUids(&ctx, os.Args[1], uids)
	} else {
		if len(os.Args) > 2 {
			importJsons(&ctx, os.Args[1], os.Args[2:])
		} else {
			exportJsons(&ctx, os.Args[1])
		}
	}
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
