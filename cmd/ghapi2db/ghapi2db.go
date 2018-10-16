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

// getEnrichCommitsDateRange return last enriched commits date
func getEnrichCommitsDateRange(c *sql.DB, ctx *lib.Ctx, repo string) (dtf time.Time, dtt time.Time, ok bool) {
	var pdt *time.Time
	rows := lib.QuerySQLWithErr(
		c,
		ctx,
		fmt.Sprintf(
			"select coalesce(max(dup_created_at), "+
				"(select min(dup_created_at) from gha_commits where dup_repo_name = %s)) "+
				"from gha_commits where author_email != '' and dup_repo_name = %s",
			lib.NValue(1),
			lib.NValue(2),
		),
		repo,
		repo,
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&pdt))
		if pdt == nil {
			if ctx.Debug > 0 {
				lib.Printf("%s: no date from\n", repo)
			}
			return
		}
		dtf = pdt.Add(time.Minute * time.Duration(-2))
	}
	lib.FatalOnError(rows.Err())
	rows = lib.QuerySQLWithErr(
		c,
		ctx,
		fmt.Sprintf(
			"select max(dup_created_at) from gha_commits where dup_repo_name = %s",
			lib.NValue(1),
		),
		repo,
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&pdt))
		if pdt == nil {
			if ctx.Debug > 0 {
				lib.Printf("%s: no date to\n", repo)
			}
			return
		}
		dtt = pdt.Add(time.Minute * time.Duration(2))
	}
	lib.FatalOnError(rows.Err())
	if ctx.Debug > 0 {
		lib.Printf("%s: %s - %s\n", repo, lib.ToYMDHMSDate(dtf), lib.ToYMDHMSDate(dtt))
	}
	ok = true
	return
}

// Search for given actor using his/her login
// If not found, return hash as its ID
func lookupActorTx(con *sql.Tx, ctx *lib.Ctx, login string, maybeHide func(string) string) int {
	hlogin := maybeHide(login)
	rows := lib.QuerySQLTxWithErr(
		con,
		ctx,
		fmt.Sprintf("select id from gha_actors where login=%s order by id desc limit 1", lib.NValue(1)),
		hlogin,
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	aid := 0
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&aid))
	}
	lib.FatalOnError(rows.Err())
	if aid == 0 {
		aid = lib.HashStrings([]string{login})
	}
	return aid
}

// Inserts single GHA Actor
func insertActorTx(con *sql.Tx, ctx *lib.Ctx, aid int64, login, name string, maybeHide func(string) string) {
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		lib.InsertIgnore("into gha_actors(id, login, name) "+lib.NValues(3)),
		lib.AnyArray{aid, maybeHide(login), maybeHide(name)}...,
	)
}

// processCommit - logic to enrich commit
func processCommit(c *sql.DB, ctx *lib.Ctx, commit *github.RepositoryCommit, maybeHide func(string) string) {
	// Check required fields
	if commit.Commit == nil {
		lib.Fatalf("Nil Commit: %+v\n", commit)
		return
	}

	// Start transaction for data possibly shared between events
	tx, err := c.Begin()
	lib.FatalOnError(err)

	// Shortcuts
	// SHA
	cSHA := *commit.SHA

	// Committer
	committerID := int64(0)
	committerLogin := ""
	if commit.Committer != nil && commit.Committer.ID != nil && commit.Committer.Login != nil {
		committerID = *commit.Committer.ID
		committerLogin = *commit.Committer.Login
	}
	committerName := *commit.Commit.Committer.Name
	committerEmail := *commit.Commit.Committer.Email
	// committerDate := *commit.Commit.Committer.Date

	// Author
	authorID := int64(0)
	authorLogin := ""
	if commit.Author != nil && commit.Author.ID != nil && commit.Author.Login != nil {
		authorID = *commit.Author.ID
		authorLogin = *commit.Author.Login
	}
	authorName := *commit.Commit.Author.Name
	authorEmail := *commit.Commit.Author.Email
	authorDate := *commit.Commit.Author.Date

	//lib.Printf("%s %v %v\n", cSHA, authorDate, committerDate)
	// Check if we already have this commit
	strAuthorDate := lib.ToYMDHMSDate(authorDate)
	rows := lib.QuerySQLTxWithErr(
		tx,
		ctx,
		fmt.Sprintf(
			"select sha, author_name, dup_created_at "+
				"from gha_commits where sha = %s "+
				"order by abs(extract(epoch from %s - dup_created_at)) "+
				"limit 1",
			lib.NValue(1),
			lib.NValue(2),
		),
		cSHA,
		strAuthorDate,
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	sha := ""
	currentAuthorName := ""
	var createdAt time.Time
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&sha, &currentAuthorName, &createdAt))
	}
	lib.FatalOnError(rows.Err())
	if sha != "" && ctx.Debug > 1 {
		lib.Printf("GHA GHAPI time difference for sha %s: %v\n", cSHA, createdAt.Sub(authorDate))
	}

	// Get existing committer & author, it is possible that we don't have them yet
	newCommitterID := int64(0)
	if committerLogin != "" {
		newCommitterID = int64(lookupActorTx(tx, ctx, committerLogin, maybeHide))
	}
	newAuthorID := int64(0)
	if authorLogin != "" {
		newAuthorID = committerID
		if authorLogin != committerLogin {
			newAuthorID = int64(lookupActorTx(tx, ctx, authorLogin, maybeHide))
		}
	}

	// Compare to what we currently have, eventually warn and insert new
	if committerLogin != "" && sha != "" && newCommitterID != committerID {
		if ctx.Debug > 0 {
			lib.Printf("DB Committer ID: %d != API Committer ID: %d, sha: %s, login: %s\n", newCommitterID, committerID, cSHA, committerLogin)
		}
		insertActorTx(tx, ctx, committerID, committerLogin, committerName, maybeHide)
	}
	if authorLogin != "" && sha != "" && authorLogin != committerLogin && newAuthorID != authorID {
		if ctx.Debug > 0 {
			lib.Printf("DB Author ID: %d != API Author ID: %d, SHA: %s, login: %s\n", newAuthorID, authorID, cSHA, authorLogin)
		}
		insertActorTx(tx, ctx, authorID, authorLogin, authorName, maybeHide)
	}

	// Same author?
	if sha != "" && currentAuthorName != authorName {
		lib.Printf("Author name mismatch API: %s, DB: %s, SHA: %s\n", authorName, currentAuthorName, cSHA)
	}

	// If we have that commit, update (enrich) it.
	if sha == "" {
		sha = *commit.SHA
		if ctx.Debug > 1 {
			lib.Printf("SHA %s not found\n", sha)
		}
	} else {
		cols := []string{
			"author_name=" + lib.NValue(1),
			"author_email=" + lib.NValue(2),
			"committer_name=" + lib.NValue(3),
			"committer_email=" + lib.NValue(4),
		}
		vals := lib.AnyArray{
			maybeHide(authorName),
			maybeHide(authorEmail),
			maybeHide(committerName),
			maybeHide(committerEmail),
		}
		nVal := 5
		if committerLogin != "" {
			cols = append(cols, "committer_id="+lib.NValue(nVal))
			vals = append(vals, committerID)
			nVal++
		}
		if authorLogin != "" {
			cols = append(cols, "author_id="+lib.NValue(nVal))
			vals = append(vals, authorID)
			nVal++
		}
		vals = append(vals, sha)
		vals = append(vals, createdAt)
		query := "update gha_commits set " + strings.Join(cols, ", ")
		query += " where sha=" + lib.NValue(nVal) + " and dup_created_at=" + lib.NValue(nVal+1)
		lib.ExecSQLTxWithErr(tx, ctx, query, vals...)
	}

	// Author email
	lib.ExecSQLTxWithErr(
		tx,
		ctx,
		lib.InsertIgnore("into gha_actors_emails(actor_id, email) "+lib.NValues(2)),
		lib.AnyArray{authorID, maybeHide(authorEmail)}...,
	)
	// Committer email
	if committerEmail != authorEmail {
		lib.ExecSQLTxWithErr(
			tx,
			ctx,
			lib.InsertIgnore("into gha_actors_emails(actor_id, email) "+lib.NValues(2)),
			lib.AnyArray{committerID, maybeHide(committerEmail)}...,
		)
	}
	// Author name
	lib.ExecSQLTxWithErr(
		tx,
		ctx,
		lib.InsertIgnore("into gha_actors_names(actor_id, name) "+lib.NValues(2)),
		lib.AnyArray{authorID, maybeHide(authorName)}...,
	)
	// Committer name
	if committerName != authorName {
		lib.ExecSQLTxWithErr(
			tx,
			ctx,
			lib.InsertIgnore("into gha_actors_names(actor_id, name) "+lib.NValues(2)),
			lib.AnyArray{committerID, maybeHide(committerName)}...,
		)
	}

	// Final commit
	// lib.FatalOnError(tx.Rollback())
	lib.FatalOnError(tx.Commit())
}

// Some debugging options (environment variables)
// You can set:
// REPO=full_repo_name
// FROM=datetime 'YYYY-MM-DD hh:mm:ss.uuuuuu"
// To use FROM make sure you set GHA2DB_RECENT_RANGE to cover that range too.
func syncCommits(ctx *lib.Ctx) {
	// Get common params
	repos, isSingleRepo, singleRepo, gctx, gc, c, recentDt := getAPIParams(ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

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
	apiCalls := 0
	var apiCallsMutex = &sync.Mutex{}
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
	opt.PerPage = 100
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
			thDtStart := time.Now()
			thLastTime := dtStart
			// To handle GDPR
			maybeHide := lib.MaybeHideFunc(lib.GetHidden(lib.HideCfgFile))
			// Need deep copy - threads
			copt := opt
			// No FROM/TO set and no GHA2DB_NO_AUTOFETCHCOMMITS
			if !isDateRange && ctx.AutoFetchCommits {
				dtf, dtt, ok := getEnrichCommitsDateRange(c, ctx, orgRepo)
				if !ok {
					ch <- false
					return
				}
				copt = &github.CommitsListOptions{
					Since:  dtf,
					Until:  dtt,
					SHA:    opt.SHA,
					Path:   opt.Path,
					Author: opt.Author,
				}
				copt.PerPage = opt.PerPage
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
								lib.Printf("Error: API limit reached while getting commits data, aborting, don't want to wait %v\n", waitPeriod)
								ch <- false
								return
							}
						}
					}
					nPages++
					if ctx.Debug > 1 {
						lib.Printf("API call for commits %s (%d), remaining GHAPI points %d\n", orgRepo, nPages, rem)
					}
					apiCallsMutex.Lock()
					apiCalls++
					apiCallsMutex.Unlock()
					commits, response, err = gc.Repositories.ListCommits(gctx, org, repo, copt)
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
							lib.Printf("Warning: not found: %s/%s\n", org, repo)
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
						lib.Printf("Error: GetRateLimit call failed %d times while getting events, aborting\n", ctx.MaxGHAPIRetry)
						ch <- false
						return
					}
				}
				// Process commits
				if ctx.Debug > 0 {
					lib.Printf("%s: processing %d commits, page %d\n", orgRepo, len(commits), nPages)
				}
				for _, commit := range commits {
					processCommit(c, ctx, commit, maybeHide)
				}
				_, thRem, thWait := lib.GetRateLimits(gctx, gc, true)
				lib.ProgressInfo(0, 0, thDtStart, &thLastTime, time.Duration(10)*time.Second, fmt.Sprintf("%s page %d, API points: %d, resets in: %v", orgRepo, nPages, thRem, thWait))
				// Handle paging
				if response.NextPage == 0 {
					break
				}
				copt.Page = response.NextPage
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
	lib.Printf("GH Commits API calls: %d\n", apiCalls)
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
	defer func() { lib.FatalOnError(c.Close()) }()

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
	apiCalls := 0
	var apiCallsMutex = &sync.Mutex{}
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
								lib.Printf("Error: API limit reached while getting issues events data, aborting, don't want to wait %v\n", waitPeriod)
								ch <- false
								return
							}
						}
					}
					nPages++
					if ctx.Debug > 1 {
						lib.Printf("API call for issues events %s (%d), remaining GHAPI points %d\n", orgRepo, nPages, rem)
					}
					apiCallsMutex.Lock()
					apiCalls++
					apiCallsMutex.Unlock()
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
							lib.Printf("Warning: not found: %s/%s\n", org, repo)
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
						lib.Printf("Error: GetRateLimit call failed %d times while getting events, aborting\n", ctx.MaxGHAPIRetry)
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
											lib.Printf("Error: API limit reached while getting PR data, aborting, don't want to wait %v\n", waitPeriod)
											ch <- false
											return
										}
									}
								}
								if ctx.Debug > 1 {
									lib.Printf("API call for %s PR: %d, remaining GHAPI points %d\n", orgRepo, prNum, rem)
								}
								apiCallsMutex.Lock()
								apiCalls++
								apiCallsMutex.Unlock()
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
									lib.Printf("Error: GetRateLimit call failed %d times while getting PR, aborting\n", ctx.MaxGHAPIRetry)
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

	// API calls
	lib.Printf("GH Repo Events/PRs API calls: %d\n", apiCalls)

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
		if !ctx.SkipAPICommits {
			syncCommits(&ctx)
		}
	}
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
