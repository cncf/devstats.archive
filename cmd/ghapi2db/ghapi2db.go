package main

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"strings"
	"time"

	lib "devstats"

	"github.com/google/go-github/github"
)

type issueConfig struct {
	repo        string
	number      int
	issueID     int64
	pr          bool
	milestoneID *int64
}

func milestoneEvent(c *sql.DB, ctx *lib.Ctx, milestone string, iid, eid int64) (err error) {
	// Create artificial event, add 2^60 to eid
	eventID := 1152921504606846976 + eid
	now := time.Now()

	// Start transaction
	tc, err := c.Begin()
	lib.FatalOnError(err)

	// Create new issue state
	lib.ExecSQLTxWithErr(
		tc,
		ctx,
		fmt.Sprintf(
			"insert into gha_issues("+
				"id, event_id, assignee_id, body, closed_at, comments, created_at, "+
				"locked, milestone_id, number, state, title, updated_at, user_id, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
				"dup_user_login, dupn_assignee_login, is_pull_request) "+
				"select id, %s, assignee_id, body, closed_at, comments, created_at, "+
				"locked, %s, number, state, title, %s, 0, "+
				"0, 'devstats-bot', dup_repo_id, dup_repo_name, 'MilestonesEvent', %s, "+
				"'devstats-bot', dupn_assignee_login, is_pull_request "+
				"from gha_issues where id = %s and event_id = %s",
			lib.NValue(1),
			milestone,
			lib.NValue(2),
			lib.NValue(3),
			lib.NValue(4),
			lib.NValue(5),
		),
		lib.AnyArray{
			eventID,
			now,
			now,
			iid,
			eid,
		}...,
	)

	// Create artificial 'MilestonesEvent' event
	lib.ExecSQLTxWithErr(
		tc,
		ctx,
		fmt.Sprintf(
			"insert into gha_events("+
				"id, type, actor_id, repo_id, public, created_at, "+
				"dup_actor_login, dup_repo_name, org_id, forkee_id) "+
				"select %s, 'MilestonesEvent', 0, repo_id, public, %s, "+
				"'devstats-bot', dup_repo_name, org_id, forkee_id "+
				"from gha_events where id = %s",
			lib.NValue(1),
			lib.NValue(2),
			lib.NValue(3),
		),
		lib.AnyArray{
			eventID,
			now,
			eid,
		}...,
	)

	// Create artificial event's payload
	lib.ExecSQLTxWithErr(
		tc,
		ctx,
		fmt.Sprintf(
			"insert into gha_payloads("+
				"event_id, push_id, size, ref, head, befor, action, "+
				"issue_id, pull_request_id, comment_id, ref_type, master_branch, commit, "+
				"description, number, forkee_id, release_id, member_id, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at) "+
				"select %s, null, null, null, null, null, 'stubbed', "+
				"issue_id, pull_request_id, null, null, null, null, "+
				"null, number, null, null, null, "+
				"0, 'devstats-bot', dup_repo_id, dup_repo_name, 'MilestonesEvent', %s "+
				"from gha_payloads where issue_id = %s and event_id = %s",
			lib.NValue(1),
			lib.NValue(2),
			lib.NValue(3),
			lib.NValue(4),
		),
		lib.AnyArray{
			eventID,
			now,
			iid,
			eid,
		}...,
	)

	// Final commit
	lib.FatalOnError(tc.Commit())
	return
}

// Insert Postgres vars
func ghapi() {
	// Environment context parse
	var ctx lib.Ctx
	ctx.Init()

	// Connect to Postgres DB
	c := lib.PgConn(&ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Connect to GitHub API
	gctx, gc := lib.GHClient(&ctx)

	// Get RateLimits info
	_, rem, wait := lib.GetRateLimits(gctx, gc, true)

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)
	lib.Printf("ghapi2db.go: Running (on %d CPUs): %d API points available, resets in %v\n", thrN, rem, wait)

	// Local or cron mode?
	dataPrefix := lib.DataDir
	if ctx.Local {
		dataPrefix = "./"
	}
	// Get recently modified opened issues/PRs
	bytes, err := ioutil.ReadFile(
		dataPrefix + "util_sql/open_issues_and_prs.sql",
	)
	lib.FatalOnError(err)
	sqlQuery := string(bytes)

	// Set range from a context
	sqlQuery = strings.Replace(sqlQuery, "{{period}}", ctx.RecentRange, -1)
	rows := lib.QuerySQLWithErr(c, &ctx, sqlQuery)
	defer func() { lib.FatalOnError(rows.Close()) }()

	// Get issues/PRs to check
	// repo, number, issueID, is_pr
	m := make(map[int]issueConfig)
	// TODO:
	/*
		repo, number, issueID, pr := "", 0, 0, false
		nIssues := 0
		for rows.Next() {
			lib.FatalOnError(rows.Scan(&repo, &number, &issueID, &pr))
			cfg := issueConfig{repo: repo, number: number, issueID: issueID, pr: pr}
			v, ok := m[issueID]
			if ok {
				if ctx.Debug > 0 {
					lib.Printf("Warning: we already have issue config for id=%d: %v, skipped new config: %v\n", issueID, v, cfg)
				}
				continue
			}
			m[issueID] = cfg
			nIssues++
		}
		lib.FatalOnError(rows.Err())
	*/
	nIssues := 1
	m[307893875] = issueConfig{repo: "kubernetes/kubernetes", number: 61579, issueID: 307893875, pr: false}

	// GitHub don't like MT quering - they say that:
	// 403 You have triggered an abuse detection mechanism. Please wait a few minutes before you try again
	// So let's get all GitHub stuff one-after-another (ugly and slow) and then spawn threads to speedup
	// Damn GitHub! - this could be working Number of CPU times faster! We're trying some hardcoded value: allowedThrN
	// Seems like GitHub is not detecting abuse when using 16 thread, but it detects when using 32.
	allowedThrN := 16
	if allowedThrN > thrN {
		allowedThrN = thrN
	}
	ch := make(chan bool)
	nThreads := 0
	dtStart := time.Now()
	lastTime := dtStart
	checked := 0
	lib.Printf("ghapi2db.go: Processing %d issues - GHAPI part\n", nIssues)
	for key := range m {
		go func(ch chan bool, iid int) {
			// Refer to current tag using index passed to anonymous function
			cfg := m[iid]
			if ctx.Debug > 0 {
				lib.Printf("GitHub Issue ID '%d' --> '%v'\n", iid, cfg)
			}
			// Get separate org and repo
			ary := strings.Split(cfg.repo, "/")
			if len(ary) != 2 {
				if ctx.Debug > 0 {
					lib.Printf("warning: wrong repository name: %s\n", cfg.repo)
				}
				return
			}
			// Use Github API to get issue info
			issue, _, err := gc.Issues.Get(gctx, ary[0], ary[1], cfg.number)
			if err != nil {
				_, rate := err.(*github.RateLimitError)
				_, abuse := err.(*github.AbuseRateLimitError)
				if abuse || rate {
					// TODO: do something more accurate here
					lib.Printf("Hit rate limit on Issues.Get for %s #%d (id=%d)\n", cfg.repo, cfg.number, cfg.issueID)
				}
				lib.FatalOnError(err)
			}
			if issue.Milestone != nil {
				cfg.milestoneID = issue.Milestone.ID
			}

			// Synchronize go routine
			if ch != nil {
				ch <- true
			}
		}(ch, key)
		// go routine called with 'ch' channel to sync and tag index

		nThreads++
		if nThreads == allowedThrN {
			<-ch
			nThreads--
			checked++
			// Get RateLimits info
			_, rem, wait := lib.GetRateLimits(gctx, gc, true)
			lib.ProgressInfo(checked, nIssues, dtStart, &lastTime, time.Duration(10)*time.Second, fmt.Sprintf("API points: %d, resets in: %v", rem, wait))
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
		lib.ProgressInfo(checked, nIssues, dtStart, &lastTime, time.Duration(10)*time.Second, fmt.Sprintf("API points: %d, resets in: %v", rem, wait))
	}

	// Now iterate all issues/PR in MT mode
	ch = make(chan bool)
	nThreads = 0
	dtStart = time.Now()
	lastTime = dtStart
	checked = 0
	updates := 0
	lib.Printf("ghapi2db.go: Processing %d issues - GHA part\n", nIssues)
	// Use map key to pass to the closure
	for key := range m {
		go func(ch chan bool, iid int) {
			// Refer to current tag using index passed to anonymous function
			cfg := m[iid]
			if ctx.Debug > 0 {
				lib.Printf("GHA Issue ID '%d' --> '%v'\n", iid, cfg)
			}
			var (
				ghaMilestoneID *int64
				ghaEventID     int64
			)
			apiMilestoneID := cfg.milestoneID
			rows := lib.QuerySQLWithErr(
				c,
				&ctx,
				fmt.Sprintf("select milestone_id, event_id from gha_issues where id = %s order by updated_at desc limit 1", lib.NValue(1)),
				cfg.issueID,
			)
			defer func() { lib.FatalOnError(rows.Close()) }()
			for rows.Next() {
				lib.FatalOnError(rows.Scan(&ghaMilestoneID, &ghaEventID))
			}
			lib.FatalOnError(rows.Err())

			// newMilestone will be non-empty when we detect that something needs to be updated
			newMilestone := ""
			if apiMilestoneID == nil && ghaMilestoneID != nil {
				newMilestone = "null"
				if ctx.Debug > 0 {
					lib.Printf("Updating issue '%v' milestone to null, it was %d\n", cfg, *ghaMilestoneID)
				}
			}
			if apiMilestoneID != nil && (ghaMilestoneID == nil || *apiMilestoneID != *ghaMilestoneID) {
				newMilestone = fmt.Sprintf("%d", *apiMilestoneID)
				if ctx.Debug > 0 {
					if ghaMilestoneID != nil {
						lib.Printf("Updating issue '%v' milestone to %d, it was %d\n", cfg, *apiMilestoneID, *ghaMilestoneID)
					} else {
						lib.Printf("Updating issue '%v' milestone to %d, it was null\n", cfg, *apiMilestoneID)
					}
				}
			}
			// Do the update if needed
			if newMilestone != "" {
				lib.FatalOnError(milestoneEvent(c, &ctx, newMilestone, cfg.issueID, ghaEventID))
				updates++
			}

			// Synchronize go routine
			if ch != nil {
				ch <- true
			}
		}(ch, key)

		// go routine called with 'ch' channel to sync and tag index
		nThreads++
		if nThreads == thrN {
			<-ch
			nThreads--
			checked++
			lib.ProgressInfo(checked, nIssues, dtStart, &lastTime, time.Duration(10)*time.Second, "")
		}
	}
	// Usually all work happens on '<-ch'
	lib.Printf("Final GHA threads join\n")
	for nThreads > 0 {
		<-ch
		nThreads--
		checked++
		lib.ProgressInfo(checked, nIssues, dtStart, &lastTime, time.Duration(10)*time.Second, "")
	}
	// Get RateLimits info
	_, rem, wait = lib.GetRateLimits(gctx, gc, true)
	lib.Printf("ghapi2db.go: Processed %d issues/PRs (%d updated): %d API points remain, resets in %v\n", checked, updates, rem, wait)
}

func main() {
	dtStart := time.Now()
	ghapi()
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
