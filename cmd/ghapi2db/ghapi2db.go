package main

import (
	"fmt"
	"time"

	lib "devstats"
)

// Insert Postgres vars
func ghapi() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Connect to Postgres DB
	c := lib.PgConn(&ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Connect to GitHub API
	gctx, gc := lib.GHClient(&ctx)

	// Get RateLimits info
	all, rem, wait := lib.GetRateLimits(gctx, gc, true)
	fmt.Printf("all=%d, rem=%d, wait=%v\n", all, rem, wait)
}

func main() {
	dtStart := time.Now()
	ghapi()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
