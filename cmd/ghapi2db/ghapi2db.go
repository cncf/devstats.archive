package main

import (
	"context"
	"database/sql"
	"fmt"
	"math"
	"os"
	"sort"
	"strconv"
	"strings"
	"sync"
	"time"

	lib "devstats"

	"github.com/google/go-github/github"
)

// getAPIParams connects to GitHub and Postgres
// Returns list of recent repositories and recent date to fetch commits from
func getAPIParams(ctx *lib.Ctx) (repos []string, isSingleRepo bool, singleRepo string, gctx context.Context, gc *github.Client, c *sql.DB, recentDt time.Time) {
	// Connect to GitHub API
	gctx, gc = lib.GHClient(ctx)

	// Connect to Postgres DB
	c = lib.PgConn(ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Get list of repositories to process
	recentReposDt := lib.GetDateAgo(c, ctx, lib.HourStart(time.Now()), ctx.RecentReposRange)
	reposA, rids := lib.GetRecentRepos(c, ctx, recentReposDt)
	if ctx.Debug > 0 {
		lib.Printf("Repos to process from %v: %v\n", recentReposDt, reposA)
	}
	// Repos can have the same ID with diffrent names
	// But they also have the same name with different IDs
	// We first need to put all repo names with unique IDs
	// And then make this names list unique as well
	ridsM := make(map[int64]struct{})
	reposM := make(map[string]struct{})
	for i := range rids {
		rid := rids[i]
		_, ok := ridsM[rid]
		if !ok {
			reposM[reposA[i]] = struct{}{}
			ridsM[rid] = struct{}{}
		}
	}
	for repo := range reposM {
		repos = append(repos, repo)
	}
	if ctx.Debug > 0 {
		lib.Printf("Unique repos: %v\n", repos)
	}
	recentDt = lib.GetDateAgo(c, ctx, lib.HourStart(time.Now()), ctx.RecentRange)

	// Single repo mode
	singleRepo = os.Getenv("REPO")
	if singleRepo != "" {
		isSingleRepo = true
	}

	return
}

func processCommit(c *sql.DB, ctx *lib.Ctx, commit *github.RepositoryCommit) {
	/*
	   "sha": "440252bdc1938899d9555196ae176d82a936fafa",
	   "commit": {
	     "author": {
	       "name": "Lukasz Gryglicki",
	       "email": "lukaszgryglicki!o2.pl",
	     },
	     "committer": {
	       "name": "Lukasz Gryglicki",
	       "email": "lukaszgryglicki!o2.pl",
	     },
	   },
	   "author": {
	     "login": "lukaszgryglicki",
	     "id": 2469783,
	   },
	   "committer": {
	     "login": "lukaszgryglicki",
	     "id": 2469783,
	   },
	*/
	fmt.Printf("%+v\n", commit)
}

// Some debugging options (environment variables)
// You can set:
// REPO=full_repo_name
// FROM=datetime 'YYYY-MM-DD hh:mm:ss.uuuuuu"
// To use FROM make sure you set GHA2DB_RECENT_RANGE to cover that range too.
func syncCommits(ctx *lib.Ctx) {
	// Get common params
	repos, isSingleRepo, singleRepo, gctx, gc, c, recentDt := getAPIParams(ctx)
	// FIXME: remove this
	if ctx.Debug > 0 {
		fmt.Printf("c=%v\n", c)
	}

	// Date range mode
	var (
		dateRangeFrom *time.Time
		dateRangeTo   *time.Time
	)
	isDateRange := false
	dateRangeFromS := os.Getenv("FROM")
	dateRangeToS := os.Getenv("TO")
	if dateRangeFromS != "" {
		tmp := lib.TimeParseAny(dateRangeFromS)
		dateRangeFrom = &tmp
		isDateRange = true
	}
	if dateRangeToS != "" {
		tmp := lib.TimeParseAny(dateRangeToS)
		dateRangeTo = &tmp
		isDateRange = true
	}

	// Process commits in parallel
	thrN := lib.GetThreadsNum(ctx)
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
	lib.Printf("ghapi2db.go: Processing %d repos - GHAPI commits part\n", nRepos)

	opt := &github.CommitsListOptions{
		Since: recentDt,
		// SHA:    "s",
		// Path:   "p",
		// Author: "a",
	}
	opt.PerPage = 2
	if isDateRange {
		if dateRangeFrom != nil {
			opt.Since = *dateRangeFrom
		}
		if dateRangeTo != nil {
			opt.Until = *dateRangeTo
		}
	}
	for _, orgRepo := range repos {
		go func(ch chan bool, orgRepo string) {
			if isSingleRepo && orgRepo != singleRepo {
				ch <- false
				return
			}
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
			var (
				err      error
				commits  []*github.RepositoryCommit
				response *github.Response
			)
			nPages := 0
			// Synchronize go routine
			// start infinite for (paging)
			for {
				got := false
				/// start trials
				for tr := 0; tr < ctx.MaxGHAPIRetry; tr++ {
					_, rem, waitPeriod := lib.GetRateLimits(gctx, gc, true)
					if ctx.Debug > 1 {
						lib.Printf("Repo commits Try: %d, rem: %v, waitPeriod: %v\n", tr, rem, waitPeriod)
					}
					if rem <= ctx.MinGHAPIPoints {
						if waitPeriod.Seconds() <= float64(ctx.MaxGHAPIWaitSeconds) {
							if ctx.Debug > 0 {
								lib.Printf("API limit reached while getting commits data, waiting %v (%d)\n", waitPeriod, tr)
							}
							time.Sleep(time.Duration(1) * time.Second)
							time.Sleep(waitPeriod)
							continue
						} else {
							if ctx.GHAPIErrorIsFatal {
								lib.Fatalf("API limit reached while getting commits data, aborting, don't want to wait %v", waitPeriod)
								os.Exit(1)
							} else {
								lib.Printf("Error: API limit reached while getting commits data, aborting, don't want to wait %v", waitPeriod)
								ch <- false
								return
							}
						}
					}
					nPages++
					if ctx.Debug > 1 {
						lib.Printf("API call for commits %s (%d), remaining GHAPI points %d\n", orgRepo, nPages, rem)
					}
					// FIXME: use "c" psql connection to get most recent enriched commit data, and query commits since then.
					// this must be configurable: on/off as a recentDT, FROM, TO replacement/helper
					commits, response, err = gc.Repositories.ListCommits(gctx, org, repo, opt)
					res := lib.HandlePossibleError(err, orgRepo, "Repositories.ListCommits")
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
				/// end trials
				if !got {
					if ctx.GHAPIErrorIsFatal {
						lib.Fatalf("GetRateLimit call failed %d times while getting events, aborting", ctx.MaxGHAPIRetry)
						os.Exit(2)
					} else {
						lib.Printf("Error: GetRateLimit call failed %d times while getting events, aborting", ctx.MaxGHAPIRetry)
						ch <- false
						return
					}
				}
				// Process commits
				for _, commit := range commits {
					processCommit(c, ctx, commit)
				}
				// Handle paging
				if response.NextPage == 0 {
					break
				}
				opt.Page = response.NextPage
			}
			// end infinite for (paging)
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
}

// Some debugging options (environment variables)
// You can set:
// REPO=full_repo_name
// FROM=datetime 'YYYY-MM-DD hh:mm:ss.uuuuuu"
// TO=datetime 'YYYY-MM-DD hh:mm:ss.uuuuuu"
// MILESTONE=milestone name
// ISSUE="issue_number"
// To use FROM and TO make sure you set GHA2DB_RECENT_RANGE to cover that range too.
func syncEvents(ctx *lib.Ctx) {
	// Get common params
	repos, isSingleRepo, singleRepo, gctx, gc, c, recentDt := getAPIParams(ctx)

	// Date range mode
	var (
		dateRangeFrom *time.Time
		dateRangeTo   *time.Time
	)
	isDateRange := false
	dateRangeFromS := os.Getenv("FROM")
	dateRangeToS := os.Getenv("TO")
	if dateRangeFromS != "" {
		tmp := lib.TimeParseAny(dateRangeFromS)
		dateRangeFrom = &tmp
		isDateRange = true
	}
	if dateRangeToS != "" {
		tmp := lib.TimeParseAny(dateRangeToS)
		dateRangeTo = &tmp
		isDateRange = true
	}

	// Single milestone mode
	isSingleMilestone := false
	singleMilestone := os.Getenv("MILESTONE")
	if singleMilestone != "" {
		isSingleMilestone = true
	}

	// Single issue mode
	isSingleIssue := false
	singleIssue := 0
	sSingleIssue := os.Getenv("ISSUE")
	if sSingleIssue != "" {
		var err error
		singleIssue, err = strconv.Atoi(sSingleIssue)
		if err == nil {
			isSingleIssue = true
		}
	}

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
	eventTypes["review_requested"] = struct{}{}
	eventTypes["review_dismissed"] = struct{}{}
	eventTypes["review_request_removed"] = struct{}{}
	eventTypes["added_to_project"] = struct{}{}
	eventTypes["removed_from_project"] = struct{}{}
	eventTypes["moved_columns_in_project"] = struct{}{}
	eventTypes["marked_as_duplicate"] = struct{}{}
	eventTypes["unmarked_as_duplicate"] = struct{}{}
	eventTypes["converted_note_to_issue"] = struct{}{}
	// Non specified in GH API but happenning
	eventTypes["base_ref_changed"] = struct{}{}
	eventTypes["comment_deleted"] = struct{}{}
	eventTypes["deployed"] = struct{}{}

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
	lib.Printf("ghapi2db.go: Processing %d repos - GHAPI Events part\n", nRepos)

	//opt := &github.ListOptions{}
	opt := &github.ListOptions{PerPage: 100}
	issues := make(map[int64]lib.IssueConfigAry)
	var issuesMutex = &sync.Mutex{}
	eids := make(map[int64][2]int64)
	eidRepos := make(map[int64][]string)
	var eidsMutex = &sync.Mutex{}
	prs := make(map[int64]github.PullRequest)
	var prsMutex = &sync.Mutex{}
	for _, orgRepo := range repos {
		go func(ch chan bool, orgRepo string) {
			if isSingleRepo && orgRepo != singleRepo {
				ch <- false
				return
			}
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
							if ctx.GHAPIErrorIsFatal {
								lib.Fatalf("API limit reached while getting issues events data, aborting, don't want to wait %v", waitPeriod)
								os.Exit(1)
							} else {
								lib.Printf("Error: API limit reached while getting issues events data, aborting, don't want to wait %v", waitPeriod)
								ch <- false
								return
							}
						}
					}
					nPages++
					if ctx.Debug > 1 {
						lib.Printf("API call for issues events %s (%d), remaining GHAPI points %d\n", orgRepo, nPages, rem)
					}
					// Returns events in GHA format
					//events, response, err = gc.Activity.ListRepositoryEvents(gctx, org, repo, opt)
					// Returns events in Issue Event format (UI events)
					events, response, err = gc.Issues.ListRepositoryEvents(gctx, org, repo, opt)
					res := lib.HandlePossibleError(err, gcfg.String(), "Issues.ListRepositoryEvents")
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
					if ctx.GHAPIErrorIsFatal {
						lib.Fatalf("GetRateLimit call failed %d times while getting events, aborting", ctx.MaxGHAPIRetry)
						os.Exit(2)
					} else {
						lib.Printf("Error: GetRateLimit call failed %d times while getting events, aborting", ctx.MaxGHAPIRetry)
						ch <- false
						return
					}
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
					if isDateRange {
						if dateRangeFrom != nil && createdAt.Before(*dateRangeFrom) {
							continue
						}
						if dateRangeTo != nil && createdAt.After(*dateRangeTo) {
							continue
						}
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
					issue := event.Issue
					if isSingleIssue && (issue.Number == nil || *issue.Number != singleIssue) {
						continue
					}
					if isSingleMilestone && (issue.Milestone == nil || issue.Milestone.Title == nil || *issue.Milestone.Title != singleMilestone) {
						continue
					}
					if createdAt.Before(recentDt) {
						continue
					}
					cfg := lib.IssueConfig{Repo: orgRepo}
					eid := *event.ID
					iid := *issue.ID
					// Check for duplicate events
					eidsMutex.Lock()
					duplicate := false
					_, o := eids[eid]
					if o {
						eids[eid] = [2]int64{iid, eids[eid][1] + 1}
						eidRepos[eid] = append(eidRepos[eid], orgRepo)
						duplicate = true
					} else {
						eids[eid] = [2]int64{iid, 1}
						eidRepos[eid] = []string{orgRepo}
					}
					eidsMutex.Unlock()
					if duplicate {
						if ctx.Debug > 0 {
							lib.Printf("Note: duplicate GH event %d, %v, %v\n", eid, eids[eid], eidRepos[eid])
						}
						ch <- false
						return
					}
					if issue.Milestone != nil {
						cfg.MilestoneID = issue.Milestone.ID
					}
					if issue.Assignee != nil {
						cfg.AssigneeID = issue.Assignee.ID
					}
					if eventType == "renamed" {
						issue.Title = event.Rename.To
					}
					cfg.EventID = *event.ID
					cfg.IssueID = *issue.ID
					cfg.EventType = eventType
					cfg.CreatedAt = createdAt
					cfg.GhIssue = issue
					cfg.GhEvent = event
					cfg.Number = *issue.Number
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
						lib.Printf("Processing %s issue number %d, event: %s, date: %s\n", cfg.Repo, cfg.Number, cfg.EventType, lib.ToYMDHMSDate(cfg.CreatedAt))
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
										if ctx.GHAPIErrorIsFatal {
											lib.Fatalf("API limit reached while getting PR data, aborting, don't want to wait %v", waitPeriod)
											os.Exit(1)
										} else {
											lib.Printf("Error: API limit reached while getting PR data, aborting, don't want to wait %v", waitPeriod)
											ch <- false
											return
										}
									}
								}
								if ctx.Debug > 1 {
									lib.Printf("API call for %s PR: %d, remaining GHAPI points %d\n", orgRepo, prNum, rem)
								}
								pr, _, err = gc.PullRequests.Get(gctx, org, repo, prNum)
								res := lib.HandlePossibleError(err, gcfg.String(), "PullRequests.Get")
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
								if ctx.GHAPIErrorIsFatal {
									lib.Fatalf("GetRateLimit call failed %d times while getting PR, aborting", ctx.MaxGHAPIRetry)
									os.Exit(2)
								} else {
									lib.Printf("Error: GetRateLimit call failed %d times while getting PR, aborting", ctx.MaxGHAPIRetry)
									ch <- false
									return
								}
							}
							if pr != nil {
								prsMutex.Lock()
								prs[cfg.IssueID] = *pr
								prsMutex.Unlock()
							}
						}
					}
				}
				if ctx.Debug > 0 {
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
		if !ctx.SkipAPIEvents {
			syncEvents(&ctx)
		}
		//if !ctx.SkipAPICommits {
		//	syncCommits(&ctx)
		//}
	}
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
