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
		//events, response, err := gc.Activity.ListEvents(gctx, opt)
		//issueEvents, response, err := gc.Activity.ListIssueEventsForRepository(gctx, "kubernetes", "kubernetes", opt)
    issueEvents, response, err := gc.Issues.ListRepositoryEvents(gctx, "kubernetes", "kubernetes", opt)
    //issueEvents, response, err := gc.Issues.ListIssueEvents(gctx, "kubernetes", "kubernetes", 65168, opt)
		fmt.Printf("events: %v\n", issueEvents)
		fmt.Printf("response: %v\n", response)
		fmt.Printf("err: %v\n", err)
		for i, event := range issueEvents {
			fmt.Printf("event %d: %+v\n", i, *event)
			jsonBytes, err := json.Marshal(event)
			lib.FatalOnError(err)
			pretty := lib.PrettyPrintJSON(jsonBytes)
			fn := fmt.Sprintf("%v.json", *(event.ID))
			lib.FatalOnError(ioutil.WriteFile(fn, pretty, 0644))
		}
		// Handle eventual paging (should not happen for labels)
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
