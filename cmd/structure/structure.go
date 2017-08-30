package main

import (
	"fmt"
	"time"

	lib "k8s.io/test-infra/gha2db"
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
			fmt.Printf("This program will recreate DB structure (dropping all existing data)\n")
		}
		fmt.Printf("Continue? (y/n) ")
		c := lib.Mgetc(&ctx)
		fmt.Printf("\n")
		if c == "y" {
			lib.Structure(&ctx)
		}
	} else {
		lib.Structure(&ctx)
	}
	dtEnd := time.Now()
	fmt.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
