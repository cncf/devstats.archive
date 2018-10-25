package main

import (
	"database/sql"
	lib "devstats"
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type esRawCommit struct {
	Type           string    `json:"type"`
	SHA            string    `json:"sha"`
	EventID        int64     `json:"event_id"`
	AuthorName     string    `json:"author_name"`
	Message        string    `json:"message"`
	ActorLogin     string    `json:"actor_login"`
	RepoName       string    `json:"repo_name"`
	CreatedAt      string    `json:"time"`
	EncryptedEmail string    `json:"encrypted_author_email"`
	AuthorEmail    string    `json:"author_email"`
	CommitterName  string    `json:"committer_name"`
	CommitterEmail string    `json:"committer_email"`
	AuthorLogin    string    `json:"author_login"`
	CommitterLogin string    `json:"committer_login"`
}

func generateRawES(ch chan struct{}, ctx *lib.Ctx, con *sql.DB, es *lib.ES, dtf, dtt time.Time, sqls map[string]string, shas map[string]string) {
	lib.Printf("Working on %v - %v\n", dtf, dtt)

	// Replace dates
	sFrom := lib.ToYMDHMSDate(dtf)
	sTo := lib.ToYMDHMSDate(dtt)
	sql := strings.Replace(sqls["commits"], "{{from}}", sFrom, -1)
	sql = strings.Replace(sql, "{{to}}", sTo, -1)

	// Execute query
	rows := lib.QuerySQLWithErr(con, ctx, sql)
	defer func() { lib.FatalOnError(rows.Close()) }()

	// ES bulk inserts
	bulkDel, bulkAdd := es.Bulks()
	var c esRawCommit
  var tm time.Time
	c.Type = "commit"
	for rows.Next() {
		lib.FatalOnError(
			rows.Scan(
				&c.SHA,
				&c.EventID,
				&c.AuthorName,
				&c.Message,
				&c.ActorLogin,
				&c.RepoName,
				&tm,
				&c.EncryptedEmail,
				&c.AuthorEmail,
				&c.CommitterName,
				&c.CommitterEmail,
				&c.AuthorLogin,
				&c.CommitterLogin,
			),
		)
    c.CreatedAt = lib.ToESDate(tm)
		es.AddBulksItemsI(ctx, bulkDel, bulkAdd, c, lib.HashArray([]interface{}{c.Type, c.SHA, c.EventID}))
	}
	lib.FatalOnError(rows.Err())
	es.ExecuteBulks(ctx, bulkDel, bulkAdd)

	if ch != nil {
		ch <- struct{}{}
	}
}

// gha2es - main working function
func gha2es(args []string) {
	var (
		ctx      lib.Ctx
		err      error
		hourFrom int
		hourTo   int
		dFrom    time.Time
		dTo      time.Time
	)

	// Environment context parse
	ctx.Init()
	if !ctx.UseES {
		return
	}
	// Connect to ElasticSearch
	es := lib.ESConn(&ctx, "d_raw_")
	// Create index
	exists := es.IndexExists(&ctx)
	if !exists {
		es.CreateIndex(&ctx, true)
	}

	// Connect to Postgres DB
	con := lib.PgConn(&ctx)
	defer func() { lib.FatalOnError(con.Close()) }()

	// Get raw commits to ES SQL
	sqls := make(map[string]string)
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}
	bytes, err := lib.ReadFile(
		&ctx,
		dataPrefix+"util_sql/es_raw_commits.sql",
	)
	lib.FatalOnError(err)
	sqls["commits"] = string(bytes)

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

	// Get number of CPUs available and optimal time window for threads
	thrN := lib.GetThreadsNum(&ctx)
	hours := int(dTo.Sub(dFrom).Hours()) / thrN
	if hours < 1 {
		hours = 1
	}
	lib.Printf("gha2es.go: Running (%v CPUs): %v - %v, interval %dh\n", thrN, dFrom, dTo, hours)

	// GDPR data hiding
	shaMap := lib.GetHidden(lib.HideCfgFile)

	dt := dFrom
	dtN := dt
	if thrN > 1 {
		ch := make(chan struct{})
		nThreads := 0
		for dt.Before(dTo) || dt.Equal(dTo) {
			dtN = dt.Add(time.Hour * time.Duration(hours))
			go generateRawES(ch, &ctx, con, es, dt, dtN, sqls, shaMap)
			dt = dtN
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
			dt = dt.Add(time.Hour * time.Duration(hours))
			generateRawES(nil, &ctx, con, es, dt, dtN, sqls, shaMap)
			dtN = dt
		}
	}
	// Finished
	lib.Printf("All done.\n")
}

func main() {
	dtStart := time.Now()
	// Required args
	if len(os.Args) < 4 {
		lib.Printf("Arguments required: date_from_YYYY-MM-DD hour_from_HH date_to_YYYY-MM-DD hour_to_HH\n")
		os.Exit(1)
	}
	gha2es(os.Args[1:])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
