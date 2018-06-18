package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"time"

	lib "devstats"

	"github.com/google/go-github/github"
)

func syncEvents(ctx *lib.Ctx) {
	// Connect to GitHub API
	gctx, gc := lib.GHClient(ctx)

	opt := &github.ListOptions{}
	// Repo events
	for {
		fmt.Printf("API call...\n")
		events, response, err := gc.Issues.ListRepositoryEvents(gctx, "kubernetes", "kubernetes", opt)
		fmt.Printf("events: %v\n", events)
		fmt.Printf("response: %v\n", response)
		fmt.Printf("err: %v\n", err)
		for i, event := range events {
			fmt.Printf("event %d: %+v\n", i, *event)
			jsonBytes, err := json.Marshal(event)
			lib.FatalOnError(err)
			pretty := lib.PrettyPrintJSON(jsonBytes)
			fn := fmt.Sprintf("%v.json", *(event.ID))
			lib.FatalOnError(ioutil.WriteFile(fn, pretty, 0644))
		}
		// Handle eventual paging (shoudl not happen for labels)
		if response.NextPage == 0 {
			break
		}
		opt.Page = response.NextPage
	}
}

func main() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	dtStart := time.Now()
	syncEvents(&ctx)
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
