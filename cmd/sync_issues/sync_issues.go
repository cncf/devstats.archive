package main

import (
	"fmt"
	"math"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	lib "devstats"

	"github.com/google/go-github/github"
)

func syncIssues(ctx *lib.Ctx) {
	// Connect to GitHub API
	gctx, gc := lib.GHClient(ctx)

	// Connect to Postgres DB
	c := lib.PgConn(ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Get SQL that will return list of issue numbers to sync
	// each issue must be full_repo_name, number
	// For example kubernetes/kubernetes, 60172
	sql := os.Getenv("GHA2DB_ISSUES_SYNC_SQL")
	if sql == "" {
		lib.Printf("You have to provide a SQL query to get a list of issue numbers to sync. Use GHA2DB_ISSUES_SYNC_SQL environment variable for this")
		lib.Fatalf("no sync issues sql query provided")
	}

	// Execute SQL
	rows := lib.QuerySQLWithErr(c, ctx, sql)
	defer func() { lib.FatalOnError(rows.Close()) }()
	numbers := []int{}
	repos := []string{}
	number := 0
	repo := ""
	seen := make(map[string]struct{})
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&repo, &number))
		key := fmt.Sprintf("%s:%d", repo, number)
		_, ok := seen[key]
		if !ok {
			numbers = append(numbers, number)
			repos = append(repos, repo)
			seen[key] = struct{}{}
		} else {
			if ctx.Debug > 0 {
				lib.Printf("Duplicated issue: %s\n", key)
			}
		}
	}
	lib.FatalOnError(rows.Err())
	nNumbers := len(numbers)
	lib.Printf("sync_issues.go: Processing %d issues - GHAPI part\n", nNumbers)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(ctx)
	// GitHub don't like MT quering - they say that:
	// 403 You have triggered an abuse detection mechanism. Please wait a few minutes before you try again
	// So let's get all GitHub stuff one-after-another (ugly and slow) and then spawn threads to speedup
	// Damn GitHub! - this could be working Number of CPU times faster! We're trying some hardcoded value: maxThreads
	// Seems like GitHub is not detecting abuse when using 16 threads, but it detects when using 32.
	maxThreads := 16
	if maxThreads > thrN {
		maxThreads = thrN
	}
	allowedThrN := maxThreads
	var thrMutex = &sync.Mutex{}
	ch := make(chan bool)
	nThreads := 0
	dtStart := time.Now()
	lastTime := dtStart
	checked := 0
	issues := make(map[int64]lib.IssueConfigAry)
	var issuesMutex = &sync.Mutex{}
	prs := make(map[int64]github.PullRequest)
	var prsMutex = &sync.Mutex{}
	artificialUID := int64(-1)
	artificialLogin := "devstats-sync"
	artificialEvent := &github.IssueEvent{Actor: &github.User{ID: &artificialUID, Login: &artificialLogin}}

	// Process issues
	for idx := range numbers {
		go func(ch chan bool, orgRepo string, number int) {
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
				err   error
				issue *github.Issue
				pr    *github.PullRequest
			)
			got := false
			for tr := 0; tr < ctx.MaxGHAPIRetry; tr++ {
				_, rem, waitPeriod := lib.GetRateLimits(gctx, gc, true)
				if ctx.Debug > 1 {
					lib.Printf("Get Issue Try: %d, rem: %v, waitPeriod: %v\n", tr, rem, waitPeriod)
				}
				if rem <= ctx.MinGHAPIPoints {
					if waitPeriod.Seconds() <= float64(ctx.MaxGHAPIWaitSeconds) {
						lib.Printf("API limit reached while getting issue data, waiting %v (%d)\n", waitPeriod, tr)
						time.Sleep(time.Duration(1) * time.Second)
						time.Sleep(waitPeriod)
						continue
					} else {
						lib.Fatalf("API limit reached while getting issue data, aborting, don't want to wait %v", waitPeriod)
						os.Exit(1)
					}
				}
				if ctx.Debug > 1 {
					lib.Printf("API call for Issue %s %d, remaining GHAPI points %d\n", orgRepo, number, rem)
				}
				issue, _, err = gc.Issues.Get(gctx, org, repo, number)
				res := lib.HandlePossibleError(err, &gcfg, "Issues.Get")
				if res != "" {
					if res == lib.Abuse {
						wait := time.Duration(int(math.Pow(2.0, float64(tr+3)))) * time.Second
						thrMutex.Lock()
						if ctx.Debug > 0 {
							lib.Printf("GitHub API abuse detected (issue), wait %v\n", wait)
						}
						if allowedThrN > 1 {
							allowedThrN--
							if ctx.Debug > 0 {
								lib.Printf("Lower threads limit (issue): %d/%d\n", nThreads, allowedThrN)
							}
						}
						thrMutex.Unlock()
						time.Sleep(wait)
					}
					if res == lib.NotFound {
						lib.Printf("Warning: not found: %s/%s %d", org, repo, number)
						ch <- false
						return
					}
					continue
				} else {
					thrMutex.Lock()
					if allowedThrN < maxThreads {
						allowedThrN++
						if ctx.Debug > 0 {
							lib.Printf("Rise threads limit (issue): %d/%d\n", nThreads, allowedThrN)
						}
					}
					thrMutex.Unlock()
				}
				got = true
				break
			}
			if !got {
				lib.Fatalf("GetRateLimit call failed %d times while getting issue, aborting", ctx.MaxGHAPIRetry)
				os.Exit(2)
			}
			cfg := lib.IssueConfig{Repo: orgRepo}
			if issue.Milestone != nil {
				cfg.MilestoneID = issue.Milestone.ID
			}
			if issue.Assignee != nil {
				cfg.AssigneeID = issue.Assignee.ID
			}
			cfg.EventType = "sync"
			cfg.CreatedAt = time.Now()
			cfg.GhIssue = issue
			cfg.GhEvent = artificialEvent
			cfg.Number = *issue.Number
			cfg.IssueID = *issue.ID
			cfg.EventID = time.Now().UnixNano() / 31622
			cfg.GhEvent.ID = &cfg.EventID
			cfg.Pr = issue.IsPullRequest()
			// Labels
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
			// Assignees
			cfg.AssigneesMap = make(map[int64]string)
			for _, assignee := range issue.Assignees {
				cfg.AssigneesMap[*assignee.ID] = *assignee.Login
			}
			assigneesAry := lib.Int64Ary{}
			for assignee := range cfg.AssigneesMap {
				assigneesAry = append(assigneesAry, assignee)
			}
			sort.Sort(assigneesAry)
			l = len(assigneesAry)
			for i, assignee := range assigneesAry {
				if i == l-1 {
					cfg.Assignees += fmt.Sprintf("%d", assignee)
				} else {
					cfg.Assignees += fmt.Sprintf("%d,", assignee)
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
				lib.Printf("Processing %v\n", cfg)
			} else if ctx.Debug == 1 {
				lib.Printf("Processing issue number %d\n", cfg.Number)
			}

			// Handle PR
			if issue.IsPullRequest() {
				prsMutex.Lock()
				_, foundPR := prs[cfg.IssueID]
				prsMutex.Unlock()
				if !foundPR {
					prNum := *issue.Number
					got = false
					for tr := 0; tr < ctx.MaxGHAPIRetry; tr++ {
						_, rem, waitPeriod := lib.GetRateLimits(gctx, gc, true)
						if ctx.Debug > 1 {
							lib.Printf("Get PR Try: %d, rem: %v, waitPeriod: %v\n", tr, rem, waitPeriod)
						}
						if rem <= ctx.MinGHAPIPoints {
							if waitPeriod.Seconds() <= float64(ctx.MaxGHAPIWaitSeconds) {
								lib.Printf("API limit reached while getting PR data, waiting %v (%d)\n", waitPeriod, tr)
								time.Sleep(time.Duration(1) * time.Second)
								time.Sleep(waitPeriod)
								continue
							} else {
								lib.Fatalf("API limit reached while getting PR data, aborting, don't want to wait %v", waitPeriod)
								os.Exit(1)
							}
						}
						if ctx.Debug > 1 {
							lib.Printf("API call for PR %s %d, remaining GHAPI points %d\n", orgRepo, prNum, rem)
						}
						pr, _, err = gc.PullRequests.Get(gctx, org, repo, prNum)
						res := lib.HandlePossibleError(err, &gcfg, "PullRequests.Get")
						if res != "" {
							if res == lib.Abuse {
								wait := time.Duration(int(math.Pow(2.0, float64(tr+3)))) * time.Second
								thrMutex.Lock()
								if ctx.Debug > 0 {
									lib.Printf("GitHub API abuse detected (get PR), wait %v\n", wait)
								}
								if allowedThrN > 1 {
									allowedThrN--
									if ctx.Debug > 0 {
										lib.Printf("Lower threads limit (get PR): %d/%d\n", nThreads, allowedThrN)
									}
								}
								thrMutex.Unlock()
								time.Sleep(wait)
							}
							continue
						} else {
							thrMutex.Lock()
							if allowedThrN < maxThreads {
								allowedThrN++
								if ctx.Debug > 0 {
									lib.Printf("Rise threads limit (get PR): %d/%d\n", nThreads, allowedThrN)
								}
							}
							thrMutex.Unlock()
						}
						got = true
						break
					}
					if !got {
						lib.Fatalf("GetRateLimit call failed %d times while getting PR, aborting", ctx.MaxGHAPIRetry)
						os.Exit(2)
					}
					if pr != nil {
						prsMutex.Lock()
						prs[cfg.IssueID] = *pr
						prsMutex.Unlock()
					}
				}
			}
			/* end handle pr */
			// Synchronize go routine
			ch <- true
		}(ch, repos[idx], numbers[idx])
		nThreads++
		for nThreads >= allowedThrN {
			<-ch
			nThreads--
			checked++
			// Get RateLimits info
			_, rem, wait := lib.GetRateLimits(gctx, gc, true)
			lib.ProgressInfo(checked, nNumbers, dtStart, &lastTime, time.Duration(10)*time.Second, fmt.Sprintf("API points: %d, resets in: %v", rem, wait))
		}
	}
	// Usually all work happens on '<-ch'
	if ctx.Debug > 1 {
		lib.Printf("Final GHAPI threads join\n")
	}
	for nThreads > 0 {
		<-ch
		nThreads--
		checked++
		// Get RateLimits info
		_, rem, wait := lib.GetRateLimits(gctx, gc, true)
		lib.ProgressInfo(checked, nNumbers, dtStart, &lastTime, time.Duration(10)*time.Second, fmt.Sprintf("API points: %d, resets in: %v", rem, wait))
	}

	// Do final corrections
	// manual sync: true
	lib.SyncIssuesState(gctx, gc, ctx, c, issues, prs, true)
}

func main() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()
	dtStart := time.Now()
	syncIssues(&ctx)
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
