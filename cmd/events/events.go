package main

import (
	"fmt"
	"sort"
	"time"

	lib "devstats"

	"github.com/google/go-github/github"
)

func syncEvents(ctx *lib.Ctx) {
	// events, response, err := gc.Activity.ListEvents(gctx, opt)
	// issueEvents, response, err := gc.Activity.ListIssueEventsForRepository(gctx, "kubernetes", "kubernetes", opt)
	// issueEvents, response, err := gc.Issues.ListIssueEvents(gctx, "kubernetes", "kubernetes", 65168, opt)
	// Connect to GitHub API
	gctx, gc := lib.GHClient(ctx)

	opt := &github.ListOptions{}
	issues := make(map[int64]lib.IssueConfigAry)
	org := lib.Kubernetes
	repo := lib.Kubernetes
	gcfg := lib.IssueConfig{
		Repo: org + "/" + repo,
	}
	var (
		err      error
		events   []*github.IssueEvent
		response *github.Response
	)
	for {
		got := false
		for tr := 1; tr <= ctx.MaxGHAPIRetry; tr++ {
			_, rem, waitPeriod := lib.GetRateLimits(gctx, gc, true)
			if rem <= ctx.MinGHAPIPoints {
				lib.Printf("API limit reached while getting events data, waiting %v (%d)\n", waitPeriod, tr)
				time.Sleep(time.Duration(1) * time.Second)
				time.Sleep(waitPeriod)
				continue
			}
			events, response, err = gc.Issues.ListRepositoryEvents(gctx, "kubernetes", "kubernetes", opt)
			lib.HandlePossibleError(err, &gcfg, "Issues.ListRepositoryEvents")
			got = true
			break
		}
		if !got {
			lib.Fatalf("GetRateLimit call failed %d times while getting events, aboorting", ctx.MaxGHAPIRetry)
			return
		}
		for _, event := range events {
			cfg := lib.IssueConfig{Repo: gcfg.Repo}
			issue := event.Issue
			if issue.Milestone != nil {
				cfg.MilestoneID = issue.Milestone.ID
			}
			cfg.CreatedAt = *event.CreatedAt
			cfg.GhIssue = issue
			cfg.Number = *issue.Number
			cfg.IssueID = *issue.ID
			cfg.Pr = issue.IsPullRequest()
			cfg.LabelsMap = make(map[int64]string)
			for _, label := range issue.Labels {
				cfg.LabelsMap[*label.ID] = *label.Name
			}
			labelsAry := lib.Int64Ary{}
			for label := range cfg.LabelsMap {
				labelsAry = append(labelsAry, label)
			}
			sort.Sort(labelsAry)
			l := len(labelsAry)
			for i, label := range labelsAry {
				if i == l-1 {
					cfg.Labels += fmt.Sprintf("%d", label)
				} else {
					cfg.Labels += fmt.Sprintf("%d,", label)
				}
			}
			_, ok := issues[cfg.IssueID]
			if ok {
				issues[cfg.IssueID] = append(issues[cfg.IssueID], cfg)
			} else {
				issues[cfg.IssueID] = []lib.IssueConfig{cfg}
			}
		}
		// Handle paging
		if response.NextPage == 0 {
			break
		}
		opt.Page = response.NextPage
		// TODO: for testing
		break
	}
	for issueID := range issues {
		sort.Sort(issues[issueID])
	}
	fmt.Printf("%+v\n", issues)
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

/*
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
*/
