package devstats

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/google/go-github/github"
	"golang.org/x/oauth2"
)

// IssueConfig - holds issue data
type IssueConfig struct {
	Repo         string
	Number       int
	IssueID      int64
	Pr           bool
	MilestoneID  *int64
	Labels       string
	LabelsMap    map[int64]string
	GhIssue      *github.Issue
	CreatedAt    time.Time
	EventID      int64
	EventType    string
	GhEvent      *github.IssueEvent
	AssigneeID   *int64
	Assignees    string
	AssigneesMap map[int64]string
}

func (ic IssueConfig) String() string {
	var (
		milestoneID int64
		assigneeID  int64
	)
	if ic.MilestoneID != nil {
		milestoneID = *ic.MilestoneID
	}
	if ic.AssigneeID != nil {
		assigneeID = *ic.AssigneeID
	}
	return fmt.Sprintf(
		"{Repo: %s, Number: %d, IssueID: %d, EventID: %d, EventType: %s, Pr: %v, MilestoneID: %d, AssigneeID: %d, CreatedAt: %s, Labels: %s, LabelsMap: %+v, Assignees: %s, AssigneesMap: %+v}",
		ic.Repo,
		ic.Number,
		ic.IssueID,
		ic.EventID,
		ic.EventType,
		ic.Pr,
		milestoneID,
		assigneeID,
		ToYMDHMSDate(ic.CreatedAt),
		ic.Labels,
		ic.LabelsMap,
		ic.Assignees,
		ic.AssigneesMap,
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
	if ic[i].CreatedAt != ic[j].CreatedAt {
		return ic[i].CreatedAt.Before(ic[j].CreatedAt)
	}
	return ic[i].EventID < ic[j].EventID
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

// HandlePossibleError - display error specific message, detect rate limit and abuse
func HandlePossibleError(err error, cfg *IssueConfig, info string) string {
	if err != nil {
		_, rate := err.(*github.RateLimitError)
		_, abuse := err.(*github.AbuseRateLimitError)
		if abuse || rate {
			if rate {
				Printf("Rate limit (%s) for %v\n", info, cfg)
				return "rate"
			}
			if abuse {
				Printf("Abuse detected (%s) for %v\n", info, cfg)
				return Abuse
			}
		}
		//FatalOnError(err)
		Printf("%s error: %v, non fatal, exiting 0 status\n", os.Args[0], err)
		os.Exit(0)
	}
	return ""
}

func ghActorIDOrNil(actPtr *github.User) interface{} {
	if actPtr == nil {
		return nil
	}
	return actPtr.ID
}

func ghActorLoginOrNil(actPtr *github.User, maybeHide func(string) string) interface{} {
	if actPtr == nil {
		return nil
	}
	if actPtr.Login == nil {
		return nil
	}
	return maybeHide(*actPtr.Login)
}

func ghMilestoneIDOrNil(milPtr *github.Milestone) interface{} {
	if milPtr == nil {
		return nil
	}
	return milPtr.ID
}

// Inserts single GitHub User
func ghActor(con *sql.Tx, ctx *Ctx, actor *github.User, maybeHide func(string) string) {
	if actor == nil || actor.Login == nil {
		return
	}
	ExecSQLTxWithErr(
		con,
		ctx,
		InsertIgnore("into gha_actors(id, login, name) "+NValues(3)),
		AnyArray{actor.ID, maybeHide(*actor.Login), ""}...,
	)
}

// Insert single GitHub milestone
func ghMilestone(con *sql.Tx, ctx *Ctx, eid int64, ic *IssueConfig, maybeHide func(string) string) {
	milestone := ic.GhIssue.Milestone
	ev := ic.GhEvent
	// gha_milestones
	ExecSQLTxWithErr(
		con,
		ctx,
		fmt.Sprintf(
			"insert into gha_milestones("+
				"id, event_id, closed_at, closed_issues, created_at, creator_id, "+
				"description, due_on, number, open_issues, state, title, updated_at, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
				"dupn_creator_login) values("+
				"%s, %s, %s, %s, %s, %s, "+
				"%s, %s, %s, %s, %s, %s, %s, "+
				"%s, %s, (select max(id) from gha_repos where name = %s), %s, %s, %s, "+
				"%s)",
			NValue(1),
			NValue(2),
			NValue(3),
			NValue(4),
			NValue(5),
			NValue(6),
			NValue(7),
			NValue(8),
			NValue(9),
			NValue(10),
			NValue(11),
			NValue(12),
			NValue(13),
			NValue(14),
			NValue(15),
			NValue(16),
			NValue(17),
			NValue(18),
			NValue(19),
			NValue(20),
		),
		AnyArray{
			ic.MilestoneID,
			eid,
			milestone.ClosedAt,
			milestone.ClosedIssues,
			milestone.CreatedAt,
			ghActorIDOrNil(milestone.Creator),
			TruncStringOrNil(milestone.Description, 0xffff),
			milestone.DueOn,
			milestone.Number,
			milestone.OpenIssues,
			milestone.State,
			TruncStringOrNil(milestone.Title, 200),
			milestone.UpdatedAt,
			ev.Actor.ID,
			maybeHide(*ev.Actor.Login),
			ic.Repo,
			ic.Repo,
			ic.EventType,
			ic.CreatedAt,
			ghActorLoginOrNil(milestone.Creator, maybeHide),
		}...,
	)
}

// GetRecentRepos - get list of repos active last day
func GetRecentRepos(c *sql.DB, ctx *Ctx) (repos []string) {
	rows := QuerySQLWithErr(
		c,
		ctx,
		"select distinct dup_repo_name from gha_events "+
			"where created_at > now() - '1 day'::interval",
	)
	defer func() { FatalOnError(rows.Close()) }()
	var repo string
	for rows.Next() {
		FatalOnError(rows.Scan(&repo))
		repos = append(repos, repo)
	}
	FatalOnError(rows.Err())
	return
}

// ArtificialEvent - create artificial 'ArtificialEvent'
// creates new issue state, artificial event and its payload
func ArtificialEvent(c *sql.DB, ctx *Ctx, cfg *IssueConfig) (err error) {
	// github.com/google/go-github/github/issues_events.go
	if ctx.SkipPDB {
		if ctx.Debug > 0 {
			Printf("Skipping adding '%v'\n", *cfg)
		}
		return nil
	}
	// Create artificial event, add 2^48 to eid
	eid := cfg.EventID
	iid := cfg.IssueID
	issue := cfg.GhIssue
	event := cfg.GhEvent
	eventID := 281474976710656 + eid
	now := cfg.CreatedAt

	// To handle GDPR
	maybeHide := MaybeHideFunc(GetHidden(HideCfgFile))

	// Start transaction
	tc, err := c.Begin()
	FatalOnError(err)

	// Actors
	ghActor(tc, ctx, issue.Assignee, maybeHide)
	ghActor(tc, ctx, issue.User, maybeHide)
	for _, assignee := range issue.Assignees {
		ghActor(tc, ctx, assignee, maybeHide)
	}
	if issue.Milestone != nil {
		ghActor(tc, ctx, issue.Milestone.Creator, maybeHide)
	}

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
				"values(%s, %s, %s, %s, %s, %s, %s, "+
				"%s, %s, %s, %s, %s, %s, %s, "+
				"%s, %s, (select max(id) from gha_repos where name = %s), %s, %s, %s, "+
				"%s, %s, %s) ",
			NValue(1),
			NValue(2),
			NValue(3),
			NValue(4),
			NValue(5),
			NValue(6),
			NValue(7),
			NValue(8),
			NValue(9),
			NValue(10),
			NValue(11),
			NValue(12),
			NValue(13),
			NValue(14),
			NValue(15),
			NValue(16),
			NValue(17),
			NValue(18),
			NValue(19),
			NValue(20),
			NValue(21),
			NValue(22),
			NValue(23),
		),
		AnyArray{
			iid,
			eventID,
			ghActorIDOrNil(issue.Assignee),
			TruncStringOrNil(issue.Body, 0xffff),
			TimeOrNil(issue.ClosedAt),
			IntOrNil(issue.Comments),
			issue.CreatedAt,
			BoolOrNil(issue.Locked),
			ghMilestoneIDOrNil(issue.Milestone),
			issue.Number,
			issue.State,
			issue.Title,
			now,
			ghActorIDOrNil(issue.User),
			ghActorIDOrNil(event.Actor),
			ghActorLoginOrNil(event.Actor, maybeHide),
			cfg.Repo,
			cfg.Repo,
			cfg.EventType,
			now,
			ghActorLoginOrNil(issue.User, maybeHide),
			ghActorLoginOrNil(issue.Assignee, maybeHide),
			issue.IsPullRequest(),
		}...,
	)

	// Create Milestone if new event and milestone non-null
	if issue.Milestone != nil {
		ghMilestone(tc, ctx, eventID, cfg, maybeHide)
	}

	// Create artificial 'ArtificialEvent' event
	ExecSQLTxWithErr(
		tc,
		ctx,
		fmt.Sprintf(
			"insert into gha_events("+
				"id, type, actor_id, repo_id, public, created_at, "+
				"dup_actor_login, dup_repo_name, org_id, forkee_id) "+
				"values(%s, %s, %s, (select max(id) from gha_repos where name = %s), true, %s, "+
				"%s, %s, (select max(org_id) from gha_repos where name = %s), null)",
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
			eventID,
			cfg.EventType,
			ghActorIDOrNil(event.Actor),
			cfg.Repo,
			now,
			ghActorLoginOrNil(event.Actor, maybeHide),
			cfg.Repo,
			cfg.Repo,
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
				"values(%s, null, null, null, null, null, %s, "+
				"%s, null, null, null, null, null, "+
				"null, %s, null, null, null, "+
				"%s, %s, (select max(id) from gha_repos where name = %s), %s, %s, %s)",
			NValue(1),
			NValue(2),
			NValue(3),
			NValue(4),
			NValue(5),
			NValue(6),
			NValue(7),
			NValue(8),
			NValue(9),
			NValue(10),
		),
		AnyArray{
			eventID,
			cfg.EventType,
			iid,
			issue.Number,
			ghActorIDOrNil(event.Actor),
			ghActorLoginOrNil(event.Actor, maybeHide),
			cfg.Repo,
			cfg.Repo,
			cfg.EventType,
			now,
		}...,
	)

	// Add issue labels
	for labelID, labelName := range cfg.LabelsMap {
		ExecSQLTxWithErr(
			tc,
			ctx,
			fmt.Sprintf(
				"insert into gha_issues_labels(issue_id, event_id, label_id, "+
					"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, "+
					"dup_type, dup_created_at, dup_issue_number, dup_label_name) "+
					"values(%s, %s, %s, "+
					"%s, %s, (select max(id) from gha_repos where name = %s), %s, "+
					"%s, %s, %s, %s)",
				NValue(1),
				NValue(2),
				NValue(3),
				NValue(4),
				NValue(5),
				NValue(6),
				NValue(7),
				NValue(8),
				NValue(9),
				NValue(10),
				NValue(11),
			),
			AnyArray{
				iid,
				eventID,
				labelID,
				ghActorIDOrNil(event.Actor),
				ghActorLoginOrNil(event.Actor, maybeHide),
				cfg.Repo,
				cfg.Repo,
				cfg.EventType,
				now,
				issue.Number,
				labelName,
			}...,
		)
	}

	// Add issue assignees
	for assigneeID := range cfg.AssigneesMap {
		ExecSQLTxWithErr(
			tc,
			ctx,
			fmt.Sprintf(
				"insert into gha_issues_assignees(issue_id, event_id, assignee_id) "+
					"values(%s, %s, %s)",
				NValue(1),
				NValue(2),
				NValue(3),
			),
			AnyArray{
				iid,
				eventID,
				assigneeID,
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
	nIssuesBefore := 0
	for _, issueConfig := range issues {
		nIssuesBefore += len(issueConfig)
	}

	// Make sure we only have single event per single second - final state
	// Sort by iid then created_at then event_id
	for issueID := range issues {
		sort.Sort(issues[issueID])
		if ctx.Debug > 1 {
			Printf("Sorted: %+v\n", issues[issueID])
		}
	}
	// Leave only final state
	for iid, issueConfigAry := range issues {
		mp := make(map[string]IssueConfig)
		for _, issue := range issueConfigAry {
			sdt := ToYMDHMSDate(issue.CreatedAt)
			mp[sdt] = issue
		}
		sdts := []string{}
		for sdt := range mp {
			sdts = append(sdts, sdt)
		}
		sort.Strings(sdts)
		issues[iid] = []IssueConfig{}
		for _, sdt := range sdts {
			issues[iid] = append(issues[iid], mp[sdt])
		}
	}

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
	// updates:
	// 0: no such event --> new
	// 1: artificial exists --> skip
	// 2: normal exists, no new
	// 3: normal exists, new needed
	updates := []int{0, 0, 0, 0}
	nIssues := 0
	for _, issueConfig := range issues {
		nIssues += len(issueConfig)
	}

	Printf("ghapi2db.go: Processing %d issues (%d with date collisions) - GHA part\n", nIssues, nIssuesBefore)
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
					ghaClosedAt    *time.Time
					ghaState       string
					ghaTitle       string
					ghaLocked      bool
					ghaAssigneeID  *int64
				)

				// Process current milestone
				apiMilestoneID := cfg.MilestoneID
				apiClosedAt := cfg.GhIssue.ClosedAt
				apiState := *cfg.GhIssue.State
				apiTitle := *cfg.GhIssue.Title
				apiLocked := *cfg.GhIssue.Locked
				apiAssigneeID := cfg.AssigneeID
				rowsM := QuerySQLWithErr(
					c,
					ctx,
					fmt.Sprintf(
						"select milestone_id, event_id, closed_at, state, title, locked, assignee_id "+
							"from gha_issues where id = %s and updated_at = %s "+
							"order by updated_at desc, event_id desc limit 1",
						NValue(1),
						NValue(2),
					),
					cfg.IssueID,
					cfg.CreatedAt,
				)
				defer func() { FatalOnError(rowsM.Close()) }()
				got := false
				for rowsM.Next() {
					FatalOnError(
						rowsM.Scan(
							&ghaMilestoneID,
							&ghaEventID,
							&ghaClosedAt,
							&ghaState,
							&ghaTitle,
							&ghaLocked,
							&ghaAssigneeID,
						),
					)
					got = true
				}
				FatalOnError(rowsM.Err())
				if !got {
					if ctx.Debug > 0 {
						Printf("Adding missing event '%v'\n", cfg)
					}
					FatalOnError(
						ArtificialEvent(
							c,
							ctx,
							&cfg,
						),
					)
					updatesMutex.Lock()
					updates[0]++
					updatesMutex.Unlock()
					ch <- true
					return
				}
				if ghaEventID > 281474976710656 {
					if ctx.Debug > 0 {
						Printf("Artificial event already exists, skipping: '%v'\n", cfg)
					}
					updatesMutex.Lock()
					updates[1]++
					updatesMutex.Unlock()
					ch <- false
					return
				}

				// Check state change
				changedState := false
				if apiState != ghaState {
					changedState = true
					if ctx.Debug > 0 {
						Printf("Updating issue '%v' state %s -> %s\n", cfg, ghaState, apiState)
					}
				}

				// Check title change
				changedTitle := false
				if apiTitle != ghaTitle {
					changedTitle = true
					if ctx.Debug > 0 {
						Printf("Updating issue '%v' title %s -> %s\n", cfg, ghaTitle, apiTitle)
					}
				}

				// Check locked change
				changedLocked := false
				if apiLocked != ghaLocked {
					changedLocked = true
					if ctx.Debug > 0 {
						Printf("Updating issue '%v' locked %s -> %s\n", cfg, ghaLocked, apiLocked)
					}
				}

				// Check closed_at change
				changedClosed := false
				if (apiClosedAt == nil && ghaClosedAt != nil) || (apiClosedAt != nil && ghaClosedAt == nil) || (apiClosedAt != nil && ghaClosedAt != nil && ToYMDHMSDate(*apiClosedAt) != ToYMDHMSDate(*ghaClosedAt)) {
					changedClosed = true
					if ctx.Debug > 0 {
						from := Null
						if ghaClosedAt != nil {
							from = fmt.Sprintf("%v", ToYMDHMSDate(*ghaClosedAt))
						}
						to := Null
						if apiClosedAt != nil {
							to = fmt.Sprintf("%v", ToYMDHMSDate(*apiClosedAt))
						}
						Printf("Updating issue '%v' closed_at %s -> %s\n", cfg, from, to)
					}
				}

				// Check milestone change
				changedMilestone := false
				if (apiMilestoneID == nil && ghaMilestoneID != nil) || (apiMilestoneID != nil && ghaMilestoneID == nil) || (apiMilestoneID != nil && ghaMilestoneID != nil && *apiMilestoneID != *ghaMilestoneID) {
					changedMilestone = true
					if ctx.Debug > 0 {
						from := Null
						if ghaMilestoneID != nil {
							from = fmt.Sprintf("%d", *ghaMilestoneID)
						}
						to := Null
						if apiMilestoneID != nil {
							to = fmt.Sprintf("%d", *apiMilestoneID)
						}
						Printf("Updating issue '%v' milestone %s -> %s\n", cfg, from, to)
					}
				}

				// Check assignee change
				changedAssignee := false
				if (apiAssigneeID == nil && ghaAssigneeID != nil) || (apiAssigneeID != nil && ghaAssigneeID == nil) || (apiAssigneeID != nil && ghaAssigneeID != nil && *apiAssigneeID != *ghaAssigneeID) {
					changedAssignee = true
					if ctx.Debug > 0 {
						from := Null
						if ghaAssigneeID != nil {
							from = fmt.Sprintf("%d", *ghaAssigneeID)
						}
						to := Null
						if apiAssigneeID != nil {
							to = fmt.Sprintf("%d", *apiAssigneeID)
						}
						Printf("Updating issue '%v' assignee %s -> %s\n", cfg, from, to)
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
				changedLabels := false
				if ctx.Debug > 0 && ghaLabels != cfg.Labels {
					Printf("Updating issue '%v' labels to '%s', they were: '%s' (event_id %d)\n", cfg, cfg.Labels, ghaLabels, ghaEventID)
					changedLabels = true
				}

				// Process current assignees
				rowsA := QuerySQLWithErr(
					c,
					ctx,
					fmt.Sprintf(
						"select coalesce(string_agg(sub.assignee_id::text, ','), '') from "+
							"(select assignee_id from gha_issues_assignees where event_id = %s "+
							"order by assignee_id) sub",
						NValue(1),
					),
					ghaEventID,
				)
				defer func() { FatalOnError(rowsA.Close()) }()
				ghaAssignees := ""
				for rowsA.Next() {
					FatalOnError(rowsA.Scan(&ghaAssignees))
				}
				FatalOnError(rowsA.Err())
				changedAssignees := false
				if ctx.Debug > 0 && ghaAssignees != cfg.Assignees {
					Printf("Updating issue '%v' assignees to '%s', they were: '%s' (event_id %d)\n", cfg, cfg.Assignees, ghaAssignees, ghaEventID)
					changedAssignees = true
				}

				uidx := 2
				// Do the update if needed
				changedAnything := changedMilestone || changedState || changedClosed || changedAssignee || changedTitle || changedLocked || changedLabels || changedAssignees
				if changedAnything {
					uidx = 3
					FatalOnError(
						ArtificialEvent(
							c,
							ctx,
							&cfg,
						),
					)
				}

				if ctx.Debug > 0 {
					Printf("Event for the same date exist, added artificial: %v: '%v'\n", changedAnything, cfg)
				}
				updatesMutex.Lock()
				updates[uidx]++
				updatesMutex.Unlock()
				// Synchronize go routine
				ch <- changedAnything
				return
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
		"ghapi2db.go: Processed %d issues/PRs (%d new for date, %d artificial exists, date exists: %d not needed, %d added): %d API points remain, resets in %v\n",
		checked, updates[0], updates[1], updates[2], updates[3], rem, wait,
	)
}
