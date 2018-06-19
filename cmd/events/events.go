package main

import (
	"database/sql"
	"fmt"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	lib "devstats"

	"github.com/google/go-github/github"
)

func getRecentRepos(c *sql.DB, ctx *lib.Ctx) (repos []string) {
	rows := lib.QuerySQLWithErr(
		c,
		ctx,
		"select distinct dup_repo_name from gha_events "+
			"where created_at > now() - '1 week'::interval",
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	var repo string
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&repo))
		repos = append(repos, repo)
	}
	lib.FatalOnError(rows.Err())
	return
}

func syncEvents(ctx *lib.Ctx) {
	// events, response, err := gc.Activity.ListEvents(gctx, opt)
	// issueEvents, response, err := gc.Activity.ListIssueEventsForRepository(gctx, "kubernetes", "kubernetes", opt)
	// issueEvents, response, err := gc.Issues.ListIssueEvents(gctx, "kubernetes", "kubernetes", 65168, opt)

	// Connect to GitHub API
	gctx, gc := lib.GHClient(ctx)
	// Connect to Postgres DB
	c := lib.PgConn(ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// get list of repositories to process
	repos := getRecentRepos(c, ctx)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(ctx)
	// GitHub don't like MT quering - they say that:
	// 403 You have triggered an abuse detection mechanism. Please wait a few minutes before you try again
	// So let's get all GitHub stuff one-after-another (ugly and slow) and then spawn threads to speedup
	// Damn GitHub! - this could be working Number of CPU times faster! We're trying some hardcoded value: allowedThrN
	// Seems like GitHub is not detecting abuse when using 24 threads, but it detects when using 32.
	allowedThrN := 24
	if allowedThrN > thrN {
		allowedThrN = thrN
	}
	ch := make(chan bool)
	nThreads := 0
	dtStart := time.Now()
	lastTime := dtStart
	checked := 0
	nRepos := len(repos)
	lib.Printf("ghapi2db.go: Processing %d repos - GHAPI part\n", nRepos)

	//opt := &github.ListOptions{}
	opt := &github.ListOptions{PerPage: 1000}
	issues := make(map[int64]lib.IssueConfigAry)
	var issuesMutex = &sync.Mutex{}
	for _, orgRepo := range repos {
		go func(ch chan bool, orgRepo string) {
			ary := strings.Split(orgRepo, "/")
			if len(ary) < 2 {
				ch <- false
				return
			}
			org := ary[0]
			repo := ary[1]
			if org == "" || repo == "" {
				ch <- false
				return
			}
			gcfg := lib.IssueConfig{
				Repo: orgRepo,
			}
			var (
				err      error
				events   []*github.IssueEvent
				response *github.Response
			)
			nPages := 0
			recentDt := lib.GetDateAgo(c, ctx, lib.HourStart(time.Now()), ctx.RecentRange)
			lib.FatalOnError(err)
			for {
				got := false
				for tr := 1; tr <= ctx.MaxGHAPIRetry; tr++ {
					_, rem, waitPeriod := lib.GetRateLimits(gctx, gc, true)
					if rem <= ctx.MinGHAPIPoints {
						if waitPeriod.Seconds() <= float64(ctx.MaxGHAPIWaitSeconds) {
							lib.Printf("API limit reached while getting events data, waiting %v (%d)\n", waitPeriod, tr)
							time.Sleep(time.Duration(1) * time.Second)
							time.Sleep(waitPeriod)
							continue
						} else {
							lib.Fatalf("API limit reached while getting issue data, aborting, don't want to wait %v", waitPeriod)
							os.Exit(1)
						}
					}
					nPages++
					if ctx.Debug >= 0 {
						lib.Printf("API call for %s (%d), remaining GHAPI points %d\n", gcfg.Repo, nPages, rem)
					}
					events, response, err = gc.Issues.ListRepositoryEvents(gctx, org, repo, opt)
					lib.HandlePossibleError(err, &gcfg, "Issues.ListRepositoryEvents")
					got = true
					break
				}
				if !got {
					lib.Fatalf("GetRateLimit call failed %d times while getting events, aboorting", ctx.MaxGHAPIRetry)
					os.Exit(2)
				}
				minCreatedAt := time.Now()
				maxCreatedAt := recentDt
				for _, event := range events {
					createdAt := *event.CreatedAt
					if createdAt.Before(minCreatedAt) {
						minCreatedAt = createdAt
					}
					if createdAt.After(maxCreatedAt) {
						maxCreatedAt = createdAt
					}
					cfg := lib.IssueConfig{Repo: gcfg.Repo}
					issue := event.Issue
					if issue.Milestone != nil {
						cfg.MilestoneID = issue.Milestone.ID
					}
					cfg.CreatedAt = createdAt
					cfg.GhIssue = issue
					cfg.Number = *issue.Number
					cfg.IssueID = *issue.ID
					cfg.EventID = *event.ID
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
					issuesMutex.Lock()
					_, ok := issues[cfg.IssueID]
					if ok {
						issues[cfg.IssueID] = append(issues[cfg.IssueID], cfg)
					} else {
						issues[cfg.IssueID] = []lib.IssueConfig{cfg}
					}
					issuesMutex.Unlock()
					if ctx.Debug > 0 {
						lib.Printf("%v\n", cfg)
					}
				}
				if ctx.Debug > 0 {
					lib.Printf("%s: [%v - %v] < %v: %v\n", gcfg.Repo, minCreatedAt, maxCreatedAt, recentDt, minCreatedAt.Before(recentDt))
				}
				if minCreatedAt.Before(recentDt) {
					break
				}
				// Handle paging
				if response.NextPage == 0 {
					break
				}
				opt.Page = response.NextPage
			}
			// Synchronize go routine
			ch <- true
		}(ch, orgRepo)
		nThreads++
		if nThreads == allowedThrN {
			<-ch
			nThreads--
			checked++
			// Get RateLimits info
			_, rem, wait := lib.GetRateLimits(gctx, gc, true)
			lib.ProgressInfo(checked, nRepos, dtStart, &lastTime, time.Duration(10)*time.Second, fmt.Sprintf("API points: %d, resets in: %v", rem, wait))
		}
	}
	// Usually all work happens on '<-ch'
	lib.Printf("Final GHAPI threads join\n")
	for nThreads > 0 {
		<-ch
		nThreads--
		checked++
		// Get RateLimits info
		_, rem, wait := lib.GetRateLimits(gctx, gc, true)
		lib.ProgressInfo(checked, nRepos, dtStart, &lastTime, time.Duration(10)*time.Second, fmt.Sprintf("API points: %d, resets in: %v", rem, wait))
	}
	for issueID := range issues {
		sort.Sort(issues[issueID])
		if ctx.Debug > 1 {
			lib.Printf("Sorted: %+v\n", issues[issueID])
		}
	}

	// Do final corrections
	lib.SyncIssuesState(gctx, gc, ctx, c, issues)
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
