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

//     closed
//       The Actor closed the issue.
//       If the issue was closed by commit message, CommitID holds the SHA1 hash of the commit.
//
//     merged
//       The Actor merged into master a branch containing a commit mentioning the issue.
//       CommitID holds the SHA1 of the merge commit.
//
//     referenced
//       The Actor committed to master a commit mentioning the issue in its commit message.
//       CommitID holds the SHA1 of the commit.
//
//     reopened, locked, unlocked
//       The Actor did that to the issue.
//
//     renamed
//       The Actor changed the issue title from Rename.From to Rename.To.
//
//     mentioned
//       Someone unspecified @mentioned the Actor [sic] in an issue comment body.
//
//     assigned, unassigned
//       The Assigner assigned the issue to or removed the assignment from the Assignee.
//
//     labeled, unlabeled
//       The Actor added or removed the Label from the issue.
//
//     milestoned, demilestoned
//       The Actor added or removed the issue from the Milestone.
//
//     subscribed, unsubscribed
//       The Actor subscribed to or unsubscribed from notifications for an issue.
//
//     head_ref_deleted, head_ref_restored
//       The pull request’s branch was deleted or restored.
//
func syncEvents(ctx *lib.Ctx) {
	// Connect to GitHub API
	gctx, gc := lib.GHClient(ctx)

	// Connect to Postgres DB
	c := lib.PgConn(ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Get list of repositories to process
	recentReposDt := lib.GetDateAgo(c, ctx, lib.HourStart(time.Now()), ctx.RecentReposRange)
	repos := lib.GetRecentRepos(c, ctx, recentReposDt)
	if ctx.Debug > 0 {
		lib.Printf("Repos to process from %v: %v\n", recentReposDt, repos)
	}
	recentDt := lib.GetDateAgo(c, ctx, lib.HourStart(time.Now()), ctx.RecentRange)

	// Specify list of events to process
	eventTypes := make(map[string]struct{})
	eventTypes["closed"] = struct{}{}
	eventTypes["merged"] = struct{}{}
	eventTypes["referenced"] = struct{}{}
	eventTypes["reopened"] = struct{}{}
	eventTypes["locked"] = struct{}{}
	eventTypes["unlocked"] = struct{}{}
	eventTypes["renamed"] = struct{}{}
	eventTypes["mentioned"] = struct{}{}
	eventTypes["assigned"] = struct{}{}
	eventTypes["unassigned"] = struct{}{}
	eventTypes["labeled"] = struct{}{}
	eventTypes["unlabeled"] = struct{}{}
	eventTypes["milestoned"] = struct{}{}
	eventTypes["demilestoned"] = struct{}{}
	eventTypes["subscribed"] = struct{}{}
	eventTypes["unsubscribed"] = struct{}{}
	eventTypes["head_ref_deleted"] = struct{}{}
	eventTypes["head_ref_restored"] = struct{}{}
	// Non specified in GH API but happenning
	eventTypes["review_requested"] = struct{}{}
	eventTypes["review_dismissed"] = struct{}{}
	eventTypes["review_request_removed"] = struct{}{}
	eventTypes["added_to_project"] = struct{}{}
	eventTypes["moved_columns_in_project"] = struct{}{}

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
	nRepos := len(repos)
	lib.Printf("ghapi2db.go: Processing %d repos - GHAPI part\n", nRepos)

	//opt := &github.ListOptions{}
	opt := &github.ListOptions{PerPage: 100}
	issues := make(map[int64]lib.IssueConfigAry)
	var issuesMutex = &sync.Mutex{}
	prs := make(map[int64]github.PullRequest)
	var prsMutex = &sync.Mutex{}
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
				pr       *github.PullRequest
			)
			nPages := 0
			lib.FatalOnError(err)
			for {
				got := false
				for tr := 0; tr < ctx.MaxGHAPIRetry; tr++ {
					_, rem, waitPeriod := lib.GetRateLimits(gctx, gc, true)
					if ctx.Debug > 1 {
						lib.Printf("Issues Repo Events Try: %d, rem: %v, waitPeriod: %v\n", tr, rem, waitPeriod)
					}
					if rem <= ctx.MinGHAPIPoints {
						if waitPeriod.Seconds() <= float64(ctx.MaxGHAPIWaitSeconds) {
							if ctx.Debug > 0 {
								lib.Printf("API limit reached while getting events data, waiting %v (%d)\n", waitPeriod, tr)
							}
							time.Sleep(time.Duration(1) * time.Second)
							time.Sleep(waitPeriod)
							continue
						} else {
							lib.Fatalf("API limit reached while getting issues events data, aborting, don't want to wait %v", waitPeriod)
							os.Exit(1)
						}
					}
					nPages++
					if ctx.Debug > 1 {
						lib.Printf("API call for issues events %s (%d), remaining GHAPI points %d\n", orgRepo, nPages, rem)
					}
					events, response, err = gc.Issues.ListRepositoryEvents(gctx, org, repo, opt)
					res := lib.HandlePossibleError(err, &gcfg, "Issues.ListRepositoryEvents")
					if res != "" {
						if res == lib.Abuse {
							wait := time.Duration(int(math.Pow(2.0, float64(tr+3)))) * time.Second
							thrMutex.Lock()
							if ctx.Debug > 0 {
								lib.Printf("GitHub API abuse detected (issues events), wait %v\n", wait)
							}
							if allowedThrN > 1 {
								allowedThrN--
								if ctx.Debug > 0 {
									lib.Printf("Lower threads limit (issues events): %d/%d\n", nThreads, allowedThrN)
								}
							}
							thrMutex.Unlock()
							time.Sleep(wait)
						}
						if res == lib.NotFound {
							lib.Printf("Warning: not found: %s/%s", org, repo)
							ch <- false
							return
						}
						continue
					} else {
						thrMutex.Lock()
						if allowedThrN < maxThreads {
							allowedThrN++
							if ctx.Debug > 0 {
								lib.Printf("Rise threads limit (issues events): %d/%d\n", nThreads, allowedThrN)
							}
						}
						thrMutex.Unlock()
					}
					got = true
					break
				}
				if !got {
					lib.Fatalf("GetRateLimit call failed %d times while getting events, aborting", ctx.MaxGHAPIRetry)
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
					if event.Event == nil {
						lib.Printf("Warning: Skipping event without type\n")
						continue
					}
					eventType := *event.Event
					_, ok := eventTypes[eventType]
					if !ok {
						lib.Printf("Warning: skipping event type %s for issue %s %d\n", eventType, orgRepo, *event.Issue.Number)
						continue
					}
					if createdAt.Before(recentDt) {
						continue
					}
					cfg := lib.IssueConfig{Repo: orgRepo}
					issue := event.Issue
					if issue.Milestone != nil {
						cfg.MilestoneID = issue.Milestone.ID
					}
					if issue.Assignee != nil {
						cfg.AssigneeID = issue.Assignee.ID
					}
					if eventType == "renamed" {
						issue.Title = event.Rename.To
					}
					cfg.EventType = eventType
					cfg.CreatedAt = createdAt
					cfg.GhIssue = issue
					cfg.GhEvent = event
					cfg.Number = *issue.Number
					cfg.IssueID = *issue.ID
					cfg.EventID = *event.ID
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
					_, ok = issues[cfg.IssueID]
					if ok {
						issues[cfg.IssueID] = append(issues[cfg.IssueID], cfg)
					} else {
						issues[cfg.IssueID] = []lib.IssueConfig{cfg}
					}
					issuesMutex.Unlock()
					if ctx.Debug > 1 {
						lib.Printf("Processing %v\n", cfg)
					} else if ctx.Debug == 1 {
						lib.Printf("Processing issue number %d, event: %s, date: %s\n", cfg.Number, cfg.EventType, lib.ToYMDHMSDate(cfg.CreatedAt))
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
										if ctx.Debug > 0 {
											lib.Printf("API limit reached while getting PR data, waiting %v (%d)\n", waitPeriod, tr)
										}
										time.Sleep(time.Duration(1) * time.Second)
										time.Sleep(waitPeriod)
										continue
									} else {
										lib.Fatalf("API limit reached while getting PR data, aborting, don't want to wait %v", waitPeriod)
										os.Exit(1)
									}
								}
								if ctx.Debug > 1 {
									lib.Printf("API call for %s PR: %d, remaining GHAPI points %d\n", orgRepo, prNum, rem)
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
				}
				if ctx.Debug > 1 {
					lib.Printf("%s: [%v - %v] < %v: %v\n", orgRepo, minCreatedAt, maxCreatedAt, recentDt, minCreatedAt.Before(recentDt))
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
		for nThreads >= allowedThrN {
			<-ch
			nThreads--
			checked++
			// Get RateLimits info
			_, rem, wait := lib.GetRateLimits(gctx, gc, true)
			lib.ProgressInfo(checked, nRepos, dtStart, &lastTime, time.Duration(10)*time.Second, fmt.Sprintf("API points: %d, resets in: %v", rem, wait))
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
		lib.ProgressInfo(checked, nRepos, dtStart, &lastTime, time.Duration(10)*time.Second, fmt.Sprintf("API points: %d, resets in: %v", rem, wait))
	}

	// Do final corrections
	// manual sync: false
	lib.SyncIssuesState(gctx, gc, ctx, c, issues, prs, false)
}

func main() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	dtStart := time.Now()
	// Create artificial events
	if !ctx.SkipGHAPI {
		syncEvents(&ctx)
	}
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
