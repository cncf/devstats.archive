package main

import (
	lib "devstats"
	"time"
)

func generateWebsiteData() {
}

func main() {
	dtStart := time.Now()
	generateWebsiteData()
	dtEnd := time.Now()
	lib.Printf("Generated website data in: %v\n", dtEnd.Sub(dtStart))
}
