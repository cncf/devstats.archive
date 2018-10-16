package main

import (
	lib "devstats"
	"time"
)

func main() {
	dtStart := time.Now()
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Create database if needed
	createdDatabase := lib.CreateDatabaseIfNeeded(&ctx)

	// If we are using existing database, then display warnings
	// And ask for continue
	if !createdDatabase {
		if ctx.Table {
			lib.Printf("This program will recreate DB structure (dropping all existing data)\n")
		}
		lib.Printf("Continue? (y/n) ")
		c := lib.Mgetc(&ctx)
		lib.Printf("\n")
		if c == "y" {
			lib.Structure(&ctx)
		}
	} else {
		lib.Structure(&ctx)
	}
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
