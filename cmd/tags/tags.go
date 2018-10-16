package main

import (
	lib "devstats"
	"time"

	yaml "gopkg.in/yaml.v2"
)

// Insert TSDB tags
func calcTags() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Connect to Postgres DB
	con := lib.PgConn(&ctx)
	defer func() { lib.FatalOnError(con.Close()) }()

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}

	// Read tags to generate
	data, err := lib.ReadFile(&ctx, dataPrefix+ctx.TagsYaml)
	if err != nil {
		lib.FatalOnError(err)
		return
	}
	var allTags lib.Tags
	lib.FatalOnError(yaml.Unmarshal(data, &allTags))

	// Per project directory for SQL files
	dir := lib.Metrics
	if ctx.Project != "" {
		dir += ctx.Project + "/"
	}

	thrN := lib.GetThreadsNum(&ctx)
	// Iterate tags
	ch := make(chan bool)
	nThreads := 0
	// Use integer index to pass to go rountine
	for i := range allTags.Tags {
		go func(ch chan bool, idx int) {
			// Refer to current tag using index passed to anonymous function
			tg := &allTags.Tags[idx]
			if ctx.Debug > 0 {
				lib.Printf("Tag '%s' --> '%s'\n", tg.Name, tg.SeriesName)
			}

			// Process tag
			lib.ProcessTag(con, &ctx, tg, [][]string{})

			// Synchronize go routine
			if ch != nil {
				ch <- true
			}
		}(ch, i)
		// go routine called with 'ch' channel to sync and tag index
		nThreads++
		if nThreads == thrN {
			<-ch
			nThreads--
		}
	}
	// Usually all work happens on '<-ch'
	lib.Printf("Final threads join\n")
	for nThreads > 0 {
		<-ch
		nThreads--
	}
}

func main() {
	dtStart := time.Now()
	calcTags()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
