package main

import (
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

// deleteArtificialEvent - deletes artificial event from all tables
func deleteArtificialEvent(c *sql.DB, ctx *lib.Ctx, eid int64) (err error) {
	if ctx.SkipPDB {
		if ctx.Debug > 0 {
			lib.Printf("Skipping delete artificial event: %d\n", eid)
		}
		return nil
	}

	// Start transaction
	tc, err := c.Begin()
	lib.FatalOnError(err)

	// Delete from gha_events, gha_issues, gha_payloads, gha_issues_labels
	lib.ExecSQLTxWithErr(tc, ctx, fmt.Sprintf("delete from gha_events where id = %s", lib.NValue(1)), eid)
	lib.ExecSQLTxWithErr(tc, ctx, fmt.Sprintf("delete from gha_issues where event_id = %s", lib.NValue(1)), eid)
	lib.ExecSQLTxWithErr(tc, ctx, fmt.Sprintf("delete from gha_payloads where event_id = %s", lib.NValue(1)), eid)
	lib.ExecSQLTxWithErr(tc, ctx, fmt.Sprintf("delete from gha_issues_labels where event_id = %s", lib.NValue(1)), eid)

	// Final commit
	lib.FatalOnError(tc.Commit())
	//lib.FatalOnError(tc.Rollback())
	return
}

// cleanArtificialEvents sometimes we're adding artificial event when syncing at hh:8
// while somebody else already added new comment that made up-to-date milestone and/or label list available to GHA
// but we will have that data next hour and unneeded artificial event is created.
// Function detects such events from past, and remove them.
// Event is marked as "not needed" when previous or next event on the same issue has the same milestone and label set.
func cleanArtificialEvents(ctx *lib.Ctx) {
	// Connect to Postgres DB
	c := lib.PgConn(ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(ctx)
	lib.Printf("ghapi2db.go: Running cleanup artificial events (on %d CPUs)\n", thrN)

	var rows *sql.Rows
	minEventID := 281474976710656
	if len(ctx.OnlyEvents) > 0 {
		ary := []string{}
		for _, event := range ctx.OnlyEvents {
			ary = append(ary, strconv.FormatInt(event, 10))
		}
		lib.Printf("Processing only selected %d %v events for debugging\n", len(ctx.OnlyEvents), ctx.OnlyEvents)
		rows = lib.QuerySQLWithErr(
			c,
			ctx,
			fmt.Sprintf(
				"select id, event_id, milestone_id, updated_at, closed_at, state "+
					"from gha_issues where event_id > %d and event_id in (%s)",
				minEventID,
				strings.Join(ary, ","),
			),
		)
	} else {
		// Get all artificial events in the recent range
		rows = lib.QuerySQLWithErr(
			c,
			ctx,
			fmt.Sprintf(
				"select id, event_id, milestone_id, updated_at, closed_at, state "+
					"from gha_issues where event_id > %s "+
					"and updated_at > %s::timestamp - %s::interval",
				lib.NValue(1),
				lib.NValue(2),
				lib.NValue(3),
			),
			minEventID,
			lib.ToYMDHMSDate(lib.HourStart(time.Now())),
			ctx.RecentRange,
		)
	}
	defer func() { lib.FatalOnError(rows.Close()) }()
	var (
		issueID     int64
		eventID     int64
		milestoneID *int64
		updatedAt   time.Time
		closedAt    *time.Time
		state       string
	)
	ch := make(chan bool)
	nThreads := 0
	nRows := 0
	var counterMutex = &sync.Mutex{}
	deleted := 0
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&issueID, &eventID, &milestoneID, &updatedAt, &closedAt, &state))
		go func(ch chan bool, iid int64, eid int64, mid *int64, updated time.Time, closed *time.Time, state string) {
			// Synchronize go routine
			defer func(c chan bool) { c <- true }(ch)

			// Get last event before this artificial event
			rowsP := lib.QuerySQLWithErr(
				c,
				ctx,
				fmt.Sprintf(
					"select event_id, milestone_id, updated_at, closed_at, state from gha_issues "+
						"where id = %s and updated_at < %s order by updated_at desc limit 1",
					lib.NValue(1),
					lib.NValue(2),
				),
				iid,
				updated,
			)
			defer func() { lib.FatalOnError(rowsP.Close()) }()
			var (
				peid     int64
				pmid     *int64
				pupdated time.Time
				pclosed  *time.Time
				pstate   string
			)
			for rowsP.Next() {
				lib.FatalOnError(rowsP.Scan(&peid, &pmid, &pupdated, &pclosed, &pstate))
			}
			lib.FatalOnError(rowsP.Err())

			// Check if they differ by state, if so, we are done
			if state != pstate {
				if ctx.Debug > 0 {
					lib.Printf(
						"Issue %d, Event (%d, %d), Dates(%v, %v): state difference artificial: %s != previus: %s\n",
						iid, eid, peid, lib.ToYMDHMSDate(updated), lib.ToYMDHMSDate(pupdated), state, pstate,
					)
				}
				return
			}

			// Check if they differ by milestone, if so, then we are done
			smid := lib.Null
			spmid := lib.Null
			if mid != nil {
				smid = strconv.FormatInt(*mid, 10)
			}
			if pmid != nil {
				spmid = strconv.FormatInt(*pmid, 10)
			}
			if smid != spmid {
				if ctx.Debug > 0 {
					lib.Printf(
						"Issue %d, Event (%d, %d), Dates(%v, %v): milestone difference artificial: %s != previus: %s\n",
						iid, eid, peid, lib.ToYMDHMSDate(updated), lib.ToYMDHMSDate(pupdated), smid, spmid,
					)
				}
				return
			}

			// Check if they differ by closed_at, if so, then we are done
			sclosed := lib.Null
			spclosed := lib.Null
			if closed != nil {
				sclosed = lib.ToYMDHMSDate(*closed)
			}
			if pclosed != nil {
				spclosed = lib.ToYMDHMSDate(*pclosed)
			}
			if sclosed != spclosed {
				if ctx.Debug > 0 {
					lib.Printf(
						"Issue %d, Event (%d, %d), Dates(%v, %v): closed_at difference artificial: %s != previus: %s\n",
						iid, eid, peid, lib.ToYMDHMSDate(updated), lib.ToYMDHMSDate(pupdated), sclosed, spclosed,
					)
				}
				return
			}

			// Process current labels
			rowsL := lib.QuerySQLWithErr(
				c,
				ctx,
				fmt.Sprintf(
					"select coalesce(string_agg(sub.label_id::text, ','), '') from "+
						"(select label_id from gha_issues_labels where event_id = %s "+
						"order by label_id) sub",
					lib.NValue(1),
				),
				eid,
			)
			defer func() { lib.FatalOnError(rowsL.Close()) }()
			labels := ""
			for rowsL.Next() {
				lib.FatalOnError(rowsL.Scan(&labels))
			}
			lib.FatalOnError(rowsL.Err())

			// Process previous labels
			rowsLP := lib.QuerySQLWithErr(
				c,
				ctx,
				fmt.Sprintf(
					"select coalesce(string_agg(sub.label_id::text, ','), '') from "+
						"(select label_id from gha_issues_labels where event_id = %s "+
						"order by label_id) sub",
					lib.NValue(1),
				),
				peid,
			)
			defer func() { lib.FatalOnError(rowsLP.Close()) }()
			plabels := ""
			for rowsLP.Next() {
				lib.FatalOnError(rowsLP.Scan(&plabels))
			}
			lib.FatalOnError(rowsLP.Err())

			// Check if they differ by labels, if so, then we are done
			if labels != plabels {
				if ctx.Debug > 0 {
					lib.Printf(
						"Issue %d, Event (%d, %d), Dates(%v, %v): label set difference artificial: '%s' != previus: '%s'\n",
						iid, eid, peid, lib.ToYMDHMSDate(updated), lib.ToYMDHMSDate(pupdated), labels, plabels,
					)
				}
				return
			}

			// Get first event after this artificial event, not newer than 3 hours
			updated3h := lib.HourStart(updated).Add(3 * time.Hour)
			rowsN := lib.QuerySQLWithErr(
				c,
				ctx,
				fmt.Sprintf(
					"select event_id, milestone_id, updated_at, closed_at, state from gha_issues "+
						"where id = %s and updated_at > %s and updated_at < %s "+
						"order by updated_at asc limit 1",
					lib.NValue(1),
					lib.NValue(2),
					lib.NValue(3),
				),
				iid,
				updated,
				updated3h,
			)
			defer func() { lib.FatalOnError(rowsN.Close()) }()
			var (
				neid     int64
				nmid     *int64
				nupdated time.Time
				nclosed  *time.Time
				nstate   string
			)
			ngot := false
			for rowsN.Next() {
				lib.FatalOnError(rowsN.Scan(&neid, &nmid, &nupdated, &nclosed, &nstate))
				ngot = true
			}
			lib.FatalOnError(rowsN.Err())

			// If there is no new event yet, keep artificial event
			if !ngot {
				if ctx.Debug > 0 {
					lib.Printf(
						"Issue %d, Event (%d, -), Dates(%v, -): there is no next event in the next 2 hours\n",
						iid, eid, lib.ToYMDHMSDate(updated),
					)
				}
				return
			}

			// Check if they differ by state, if so, we are done
			if state != nstate {
				if ctx.Debug > 0 {
					lib.Printf(
						"Issue %d, Event (%d, %d), Dates(%v, %v): state difference artificial: %s != next: %s\n",
						iid, eid, neid, lib.ToYMDHMSDate(updated), lib.ToYMDHMSDate(nupdated), state, nstate,
					)
				}
				return
			}

			// Check if they differ by milestone, if so, then we are done
			snmid := lib.Null
			if nmid != nil {
				snmid = strconv.FormatInt(*nmid, 10)
			}
			if smid != snmid {
				if ctx.Debug > 0 {
					lib.Printf(
						"Issue %d, Event (%d, %d), Dates(%v, %v): milestone difference artificial: %s != next: %s\n",
						iid, eid, neid, lib.ToYMDHMSDate(updated), lib.ToYMDHMSDate(nupdated), smid, snmid,
					)
				}
				return
			}

			// Check if they differ by closed_at, if so, then we are done
			snclosed := lib.Null
			if nclosed != nil {
				snclosed = lib.ToYMDHMSDate(*nclosed)
			}
			if sclosed != snclosed {
				if ctx.Debug > 0 {
					lib.Printf(
						"Issue %d, Event (%d, %d), Dates(%v, %v): closed_at difference artificial: %s != next: %s\n",
						iid, eid, neid, lib.ToYMDHMSDate(updated), lib.ToYMDHMSDate(nupdated), sclosed, snclosed,
					)
				}
				return
			}

			// Process previous labels
			rowsLN := lib.QuerySQLWithErr(
				c,
				ctx,
				fmt.Sprintf(
					"select coalesce(string_agg(sub.label_id::text, ','), '') from "+
						"(select label_id from gha_issues_labels where event_id = %s "+
						"order by label_id) sub",
					lib.NValue(1),
				),
				neid,
			)
			defer func() { lib.FatalOnError(rowsLN.Close()) }()
			nlabels := ""
			for rowsLN.Next() {
				lib.FatalOnError(rowsLN.Scan(&nlabels))
			}
			lib.FatalOnError(rowsLN.Err())

			// Check if they differ by labels, if so, then we are done
			if labels != nlabels {
				if ctx.Debug > 0 {
					lib.Printf(
						"Issue %d, Event (%d, %d), Dates(%v, %v): label set difference artificial: '%s' != next: '%s'\n",
						iid, eid, neid, lib.ToYMDHMSDate(updated), lib.ToYMDHMSDate(nupdated), labels, nlabels,
					)
				}
				return
			}

			// Now we can delete this event
			if ctx.Debug > 0 {
				lib.Printf(
					"Removing artificial event:\n"+
						"iid=%d  eid=%d mid=%v  closed_at=%s state=%s labels=%s  updated=%v\n"+
						"iid=%d peid=%d pmid=%v closed_at=%s state=%s plabels=%s pupdated=%v\n"+
						"iid=%d neid=%d nmid=%v closed_at=%s state=%s nlabels=%s nupdated=%v\n\n",
					iid, eid, mid, sclosed, state, labels, lib.ToYMDHMSDate(updated),
					iid, peid, pmid, spclosed, pstate, plabels, lib.ToYMDHMSDate(pupdated),
					iid, neid, nmid, snclosed, nstate, nlabels, lib.ToYMDHMSDate(nupdated),
				)
			}
			// Delete artificial event
			lib.FatalOnError(deleteArtificialEvent(c, ctx, eid))

			// Safe increase counter
			counterMutex.Lock()
			deleted++
			counterMutex.Unlock()
		}(ch, issueID, eventID, milestoneID, updatedAt, closedAt, state)

		nThreads++
		if nThreads == thrN {
			<-ch
			nRows++
			nThreads--
		}
	}
	// Usually all work happens on '<-ch'
	lib.Printf("Final artificial events clean threads join\n")
	for nThreads > 0 {
		<-ch
		nRows++
		nThreads--
	}
	lib.FatalOnError(rows.Err())
	lib.Printf("Processed %d artificial events, deleted %d\n", nRows, deleted)
}

func getRecentRepos(c *sql.DB, ctx *lib.Ctx) (repos []string) {
	rows := lib.QuerySQLWithErr(
		c,
		ctx,
		"select distinct dup_repo_name from gha_events "+
			"where created_at > now() - '1 day'::interval",
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
	// Connect to GitHub API
	gctx, gc := lib.GHClient(ctx)

	// Connect to Postgres DB
	c := lib.PgConn(ctx)
	defer func() { lib.FatalOnError(c.Close()) }()

	// Get list of repositories to process
	repos := getRecentRepos(c, ctx)
	if ctx.Debug > 0 {
		lib.Printf("Repos to process: %v\n", repos)
	}

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
	recentDt := lib.GetDateAgo(c, ctx, lib.HourStart(time.Now()), ctx.RecentRange)
	lib.Printf("ghapi2db.go: Processing %d repos - GHAPI part\n", nRepos)

	//opt := &github.ListOptions{}
	opt := &github.ListOptions{PerPage: 100}
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
			lib.FatalOnError(err)
			for {
				got := false
				for tr := 0; tr < ctx.MaxGHAPIRetry; tr++ {
					_, rem, waitPeriod := lib.GetRateLimits(gctx, gc, true)
					if ctx.Debug > 0 {
						lib.Printf("Try: %d, rem: %v, waitPeriod: %v\n", tr, rem, waitPeriod)
					}
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
					if ctx.Debug > 0 {
						lib.Printf("API call for %s (%d), remaining GHAPI points %d\n", orgRepo, nPages, rem)
					}
					events, response, err = gc.Issues.ListRepositoryEvents(gctx, org, repo, opt)
					res := lib.HandlePossibleError(err, &gcfg, "Issues.ListRepositoryEvents")
					if res != "" {
						if res == lib.Abuse {
							wait := time.Duration(int(math.Pow(2.0, float64(tr+3)))) * time.Second
							thrMutex.Lock()
							lib.Printf("GitHub API abuse detected, wait %v\n", wait)
							if allowedThrN > 1 {
								allowedThrN--
								lib.Printf("Lower threads limit: %d/%d\n", nThreads, allowedThrN)
							}
							thrMutex.Unlock()
							time.Sleep(wait)
						}
						continue
					} else {
						thrMutex.Lock()
						if allowedThrN < maxThreads {
							allowedThrN++
							lib.Printf("Rise threads limit: %d/%d\n", nThreads, allowedThrN)
						}
						thrMutex.Unlock()
					}
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
					cfg := lib.IssueConfig{Repo: orgRepo}
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
					if createdAt.After(recentDt) {
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
	// Clean unneeded events
	if !ctx.SkipArtificailClean {
		cleanArtificialEvents(&ctx)
	}

	// Create artificial events
	if !ctx.SkipGHAPI {
		syncEvents(&ctx)
	}
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
