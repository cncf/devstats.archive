package main

import (
	"fmt"
	"time"

	lib "gha2db"
)

// Insert InfluxDB tags
func idbTags() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Connect to Postgres DB
	con := lib.PgConn(&ctx)
	defer con.Close()

	// Connect to InfluxDB
	ic := lib.IDBConn(&ctx)
	defer ic.Close()

	// Get BatchPoints
	bp := lib.IDBBatchPoints(&ctx, &ic)

	// Execute SQL
	rows := lib.QuerySQLWithErr(
		con,
		&ctx,
		"select 'All' as repo_group union "+
			"select distinct repo_group from gha_repos "+
			"where repo_group is not null order by repo_group",
	)
	defer rows.Close()

	// Drop current tags
	lib.SafeQueryIDB(ic, &ctx, "drop series from all_repo_groups")

	// Iterate repository groups
	repoGroup := ""
	tags := make(map[string]string)
	fields := map[string]interface{}{
		"value": 0.0,
	}
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&repoGroup))
		if ctx.Debug > 0 {
			fmt.Printf("Repo group: %v\n", repoGroup)
		}
		tags["all_repo_group_name"] = repoGroup
		tags["all_repo_group_value"] = lib.NormalizeName(repoGroup)
		// Add batch point
		pt := lib.IDBNewPointWithErr("all_repo_groups", tags, fields, time.Now())
		bp.AddPoint(pt)
	}
	lib.FatalOnError(rows.Err())

	// Execute SQL
	rows = lib.QuerySQLWithErr(
		con,
		&ctx,
		"select distinct name from gha_repos order by name",
	)
	defer rows.Close()

	// Drop current tags
	lib.SafeQueryIDB(ic, &ctx, "drop series from all_repo_names")

	// Iterate repository groups
	repoName := ""
	tags = make(map[string]string)
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&repoName))
		if ctx.Debug > 0 {
			fmt.Printf("Repo name: %v\n", repoName)
		}
		tags["all_repo_names_name"] = repoName
		tags["all_repo_names_value"] = lib.NormalizeName(repoName)
		// Add batch point
		pt := lib.IDBNewPointWithErr("all_repo_names", tags, fields, time.Now())
		bp.AddPoint(pt)
	}
	lib.FatalOnError(rows.Err())

	// Write the batch
	if !ctx.SkipIDB {
		err := ic.Write(bp)
		lib.FatalOnError(err)
	} else if ctx.Debug > 0 {
		lib.Printf("Skipping tags series write\n")
	}
}

func main() {
	dtStart := time.Now()
	idbTags()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
