package devstats

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

// IssueConfig - holds issue data
type IssueConfig struct {
	Repo        string
	Number      int
	IssueID     int64
	Pr          bool
	MilestoneID *int64
	Labels      string
	LabelsMap   map[int64]string
	GhIssue     *github.Issue
	CreatedAt   time.Time
}

func (ic IssueConfig) String() string {
	var milestoneID int64
	if ic.MilestoneID != nil {
		milestoneID = *ic.MilestoneID
	}
	return fmt.Sprintf(
		"{Repo: %s, Number: %d, IssueID: %d, Pr: %v, MilestoneID: %d, Labels: %s, CreatedAt: %v, LabelsMap: %+v}",
		ic.Repo,
		ic.Number,
		ic.IssueID,
		ic.Pr,
		milestoneID,
		ic.Labels,
		ic.CreatedAt,
		ic.LabelsMap,
	)
}

// IssueConfigAry - allows sorting IssueConfig array by IssueID annd then event creation date
type IssueConfigAry []IssueConfig

func (ic IssueConfigAry) Len() int      { return len(ic) }
func (ic IssueConfigAry) Swap(i, j int) { ic[i], ic[j] = ic[j], ic[i] }
func (ic IssueConfigAry) Less(i, j int) bool {
	if ic[i].IssueID != ic[j].IssueID {
		return ic[i].IssueID < ic[j].IssueID
	}
	return ic[i].CreatedAt.Before(ic[j].CreatedAt)
}

// ArtificialEvent - create artificial 'ArtificialEvent'
// creates new issue state, artificial event and its payload
func ArtificialEvent(
	c *sql.DB,
	ctx *Ctx,
	iid, eid int64,
	milestone string,
	labels map[int64]string,
	labelsChanged bool,
	ghIssue *github.Issue,
	createdAt time.Time,
) (err error) {
	if ctx.SkipPDB {
		if ctx.Debug > 0 {
			Printf("Skipping write for issue_id: %d, event_id: %d, milestone_id: %s, labels(%v): %v\n", iid, eid, milestone, labelsChanged, labels)
		}
		return nil
	}
	// Create artificial event, add 2^48 to eid
	eventID := 281474976710656 + eid
	now := createdAt

	// If no new milestone, just copy "milestone_id" from the source
	if milestone == "" {
		milestone = "milestone_id"
	}

	// Start transaction
	tc, err := c.Begin()
	FatalOnError(err)

	// Create new issue state
	ExecSQLTxWithErr(
		tc,
		ctx,
		fmt.Sprintf(
			"insert into gha_issues("+
				"id, event_id, assignee_id, body, closed_at, comments, created_at, "+
				"locked, milestone_id, number, state, title, updated_at, user_id, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
				"dup_user_login, dupn_assignee_login, is_pull_request) "+
				"select id, %s, assignee_id, body, %s, %s, created_at, "+
				"%s, %s, number, %s, title, %s, 0, "+
				"0, 'devstats-bot', dup_repo_id, dup_repo_name, 'ArtificialEvent', %s, "+
				"'devstats-bot', dupn_assignee_login, is_pull_request "+
				"from gha_issues where id = %s and event_id = %s",
			NValue(1),
			NValue(2),
			NValue(3),
			NValue(4),
			milestone,
			NValue(5),
			NValue(6),
			NValue(7),
			NValue(8),
			NValue(9),
		),
		AnyArray{
			eventID,
			TimeOrNil(ghIssue.ClosedAt),
			IntOrNil(ghIssue.Comments),
			BoolOrNil(ghIssue.Locked),
			StringOrNil(ghIssue.State),
			now,
			now,
			iid,
			eid,
		}...,
	)

	// Create artificial 'ArtificialEvent' event
	ExecSQLTxWithErr(
		tc,
		ctx,
		fmt.Sprintf(
			"insert into gha_events("+
				"id, type, actor_id, repo_id, public, created_at, "+
				"dup_actor_login, dup_repo_name, org_id, forkee_id) "+
				"select %s, 'ArtificialEvent', 0, repo_id, public, %s, "+
				"'devstats-bot', dup_repo_name, org_id, forkee_id "+
				"from gha_events where id = %s",
			NValue(1),
			NValue(2),
			NValue(3),
		),
		AnyArray{
			eventID,
			now,
			eid,
		}...,
	)

	// Create artificial event's payload
	ExecSQLTxWithErr(
		tc,
		ctx,
		fmt.Sprintf(
			"insert into gha_payloads("+
				"event_id, push_id, size, ref, head, befor, action, "+
				"issue_id, pull_request_id, comment_id, ref_type, master_branch, commit, "+
				"description, number, forkee_id, release_id, member_id, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at) "+
				"select %s, null, null, null, null, null, 'artificial', "+
				"issue_id, pull_request_id, null, null, null, null, "+
				"null, number, null, null, null, "+
				"0, 'devstats-bot', dup_repo_id, dup_repo_name, 'ArtificialEvent', %s "+
				"from gha_payloads where issue_id = %s and event_id = %s",
			NValue(1),
			NValue(2),
			NValue(3),
			NValue(4),
		),
		AnyArray{
			eventID,
			now,
			iid,
			eid,
		}...,
	)

	// Add issue labels
	for label, labelName := range labels {
		ExecSQLTxWithErr(
			tc,
			ctx,
			fmt.Sprintf(
				"insert into gha_issues_labels(issue_id, event_id, label_id, "+
					"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, "+
					"dup_type, dup_created_at, dup_issue_number, dup_label_name) "+
					"select %s, %s, %s, "+
					"0, 'devstats-bot', repo_id, dup_repo_name, "+
					"'ArtificialEvent', %s, "+
					"(select number from gha_issues where id = %s and event_id = %s limit 1), %s "+
					"from gha_events where id = %s",
				NValue(1),
				NValue(2),
				NValue(3),
				NValue(4),
				NValue(5),
				NValue(6),
				NValue(7),
				NValue(8),
			),
			AnyArray{
				iid,
				eventID,
				label,
				now,
				iid,
				eid,
				labelName,
				eid,
			}...,
		)
	}

	// Final commit
	FatalOnError(tc.Commit())
	//FatalOnError(tc.Rollback())
	return
}

// SyncIssuesState synchonizes issues states
func SyncIssuesState(gctx context.Context, gc *github.Client, ctx *Ctx, c *sql.DB, issues map[int64]IssueConfigAry) {
	// Get number of CPUs available
	thrN := GetThreadsNum(ctx)

	var issuesMutex = &sync.RWMutex{}
	// Now iterate all issues/PR in MT mode
	ch := make(chan bool)
	nThreads := 0
	dtStart := time.Now()
	lastTime := dtStart
	checked := 0
	var updatesMutex = &sync.Mutex{}
	updates := 0
	nIssues := len(issues)

	Printf("ghapi2db.go: Processing %d issues - GHA part\n", nIssues)
	// Use map key to pass to the closure
	for key, issueConfig := range issues {
		for idx := range issueConfig {
			go func(ch chan bool, iid int64, idx int) {
				// Refer to current tag using index passed to anonymous function
				issuesMutex.RLock()
				cfg := issues[iid][idx]
				issuesMutex.RUnlock()
				if ctx.Debug > 0 {
					Printf("GHA Issue ID '%d' --> '%v'\n", iid, cfg)
				}
				var (
					ghaMilestoneID *int64
					ghaEventID     int64
				)

				// Process current milestone
				apiMilestoneID := cfg.MilestoneID
				rowsM := QuerySQLWithErr(
					c,
					ctx,
					fmt.Sprintf("select milestone_id, event_id from gha_issues where id = %s order by updated_at desc, event_id desc limit 1", NValue(1)),
					cfg.IssueID,
				)
				defer func() { FatalOnError(rowsM.Close()) }()
				for rowsM.Next() {
					FatalOnError(rowsM.Scan(&ghaMilestoneID, &ghaEventID))
				}
				FatalOnError(rowsM.Err())

				// newMilestone will be non-empty when we detect that something needs to be updated
				newMilestone := ""
				if apiMilestoneID == nil && ghaMilestoneID != nil {
					newMilestone = Null
					if ctx.Debug > 0 {
						Printf("Updating issue '%v' milestone to null, it was %d (event_id %d)\n", cfg, *ghaMilestoneID, ghaEventID)
					}
				}
				if apiMilestoneID != nil && (ghaMilestoneID == nil || *apiMilestoneID != *ghaMilestoneID) {
					newMilestone = fmt.Sprintf("%d", *apiMilestoneID)
					if ctx.Debug > 0 {
						if ghaMilestoneID != nil {
							Printf("Updating issue '%v' milestone to %d, it was %d (event_id %d)\n", cfg, *apiMilestoneID, *ghaMilestoneID, ghaEventID)
						} else {
							Printf("Updating issue '%v' milestone to %d, it was null (event_id %d)\n", cfg, *apiMilestoneID, ghaEventID)
						}
					}
				}
				// Process current labels
				rowsL := QuerySQLWithErr(
					c,
					ctx,
					fmt.Sprintf(
						"select coalesce(string_agg(sub.label_id::text, ','), '') from "+
							"(select label_id from gha_issues_labels where event_id = %s "+
							"order by label_id) sub",
						NValue(1),
					),
					ghaEventID,
				)
				defer func() { FatalOnError(rowsL.Close()) }()
				ghaLabels := ""
				for rowsL.Next() {
					FatalOnError(rowsL.Scan(&ghaLabels))
				}
				FatalOnError(rowsL.Err())
				if ctx.Debug > 0 && ghaLabels != cfg.Labels {
					Printf("Updating issue '%v' labels to '%s', they were: '%s' (event_id %d)\n", cfg, cfg.Labels, ghaLabels, ghaEventID)
				}

				// Do the update if needed: wrong milestone or label set
				if newMilestone != "" || ghaLabels != cfg.Labels {
					FatalOnError(
						ArtificialEvent(
							c,
							ctx,
							cfg.IssueID,
							ghaEventID,
							newMilestone,
							cfg.LabelsMap,
							ghaLabels != cfg.Labels,
							cfg.GhIssue,
							cfg.CreatedAt,
						),
					)
					updatesMutex.Lock()
					updates++
					updatesMutex.Unlock()
				}

				// Synchronize go routine
				if ch != nil {
					ch <- true
				}
			}(ch, key, idx)

			// go routine called with 'ch' channel to sync and tag index
			nThreads++
			if nThreads == thrN {
				<-ch
				nThreads--
				checked++
				ProgressInfo(checked, nIssues, dtStart, &lastTime, time.Duration(10)*time.Second, "")
			}
		}
	}
	// Usually all work happens on '<-ch'
	Printf("Final GHA threads join\n")
	for nThreads > 0 {
		<-ch
		nThreads--
		checked++
		ProgressInfo(checked, nIssues, dtStart, &lastTime, time.Duration(10)*time.Second, "")
	}
	// Get RateLimits info
	_, rem, wait := GetRateLimits(gctx, gc, true)
	Printf(
		"ghapi2db.go: Processed %d issues/PRs (%d updated): %d API points remain, resets in %v\n",
		checked, updates, rem, wait,
	)
}

// HandlePossibleError - display error specific message, detect rate limit and abuse
func HandlePossibleError(err error, cfg *IssueConfig, info string) {
	if err != nil {
		_, rate := err.(*github.RateLimitError)
		_, abuse := err.(*github.AbuseRateLimitError)
		if abuse || rate {
			Printf("Hit rate limit (%s) for %v\n", info, cfg)
		}
		//FatalOnError(err)
		Printf("%s error: %v, non fatal, exiting 0 status\n", os.Args[0], err)
		os.Exit(0)
	}
}

// GetRateLimits - returns all and remaining API points and duration to wait for reset
// when core=true - returns Core limits, when core=false returns Search limits
func GetRateLimits(gctx context.Context, gc *github.Client, core bool) (int, int, time.Duration) {
	rl, _, err := gc.RateLimits(gctx)
	if err != nil {
		Printf("GetRateLimit: %v\n", err)
	}
	if rl == nil {
		return -1, -1, time.Duration(5) * time.Second
	}
	if core {
		return rl.Core.Limit, rl.Core.Remaining, rl.Core.Reset.Time.Sub(time.Now()) + time.Duration(1)*time.Second
	}
	return rl.Search.Limit, rl.Search.Remaining, rl.Search.Reset.Time.Sub(time.Now()) + time.Duration(1)*time.Second
}

// GHClient - get GitHub client
func GHClient(ctx *Ctx) (ghCtx context.Context, client *github.Client) {
	// Get GitHub OAuth from env or from file
	oAuth := ctx.GitHubOAuth
	if strings.Contains(ctx.GitHubOAuth, "/") {
		bytes, err := ReadFile(ctx, ctx.GitHubOAuth)
		FatalOnError(err)
		oAuth = strings.TrimSpace(string(bytes))
	}

	// GitHub authentication or use public access
	ghCtx = context.Background()
	if oAuth == "-" {
		client = github.NewClient(nil)
	} else {
		ts := oauth2.StaticTokenSource(
			&oauth2.Token{AccessToken: oAuth},
		)
		tc := oauth2.NewClient(ghCtx, ts)
		client = github.NewClient(tc)
	}

	return
}
