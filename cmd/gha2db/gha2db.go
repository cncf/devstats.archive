package main

import (
	"bytes"
	"compress/gzip"
	"database/sql"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"

	lib "devstats"
)

// Inserts single GHA Actor
func ghaActor(con *sql.Tx, ctx *lib.Ctx, actor *lib.Actor, maybeHide func(string) string) {
	// gha_actors
	// {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592,
	// "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
	// {"id"=>8, "login"=>34, "display_login"=>34, "gravatar_id"=>0, "url"=>63, "avatar_url"=>49}
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		lib.InsertIgnore("into gha_actors(id, login, name) "+lib.NValues(3)),
		lib.AnyArray{actor.ID, maybeHide(actor.Login), ""}...,
	)
}

// Inserts single GHA Repo
func ghaRepo(db *sql.DB, ctx *lib.Ctx, repo *lib.Repo, orgID, orgLogin interface{}) {
	// gha_repos
	// {"id:Fixnum"=>48592, "name:String"=>48592, "url:String"=>48592}
	// {"id"=>8, "name"=>111, "url"=>140}
	lib.ExecSQLWithErr(
		db,
		ctx,
		lib.InsertIgnore("into gha_repos(id, name, org_id, org_login) "+lib.NValues(4)),
		lib.AnyArray{repo.ID, repo.Name, orgID, orgLogin}...,
	)
}

// Inserts single GHA Org
func ghaOrg(db *sql.DB, ctx *lib.Ctx, org *lib.Org) {
	// gha_orgs
	// {"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494,
	// "url:String"=>18494, "avatar_url:String"=>18494}
	// {"id"=>8, "login"=>38, "gravatar_id"=>0, "url"=>66, "avatar_url"=>49}
	if org != nil {
		lib.ExecSQLWithErr(
			db,
			ctx,
			lib.InsertIgnore("into gha_orgs(id, login) "+lib.NValues(2)),
			lib.AnyArray{org.ID, org.Login}...,
		)
	}
}

// Inserts single GHA Milestone
func ghaMilestone(con *sql.Tx, ctx *lib.Ctx, eid string, milestone *lib.Milestone, ev *lib.Event, maybeHide func(string) string) {
	// creator
	if milestone.Creator != nil {
		ghaActor(con, ctx, milestone.Creator, maybeHide)
	}

	// gha_milestones
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		"insert into gha_milestones("+
			"id, event_id, closed_at, closed_issues, created_at, creator_id, "+
			"description, due_on, number, open_issues, state, title, updated_at, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dupn_creator_login) "+lib.NValues(20),
		lib.AnyArray{
			milestone.ID,
			eid,
			lib.TimeOrNil(milestone.ClosedAt),
			milestone.ClosedIssues,
			milestone.CreatedAt,
			lib.ActorIDOrNil(milestone.Creator),
			lib.TruncStringOrNil(milestone.Description, 0xffff),
			lib.TimeOrNil(milestone.DueOn),
			milestone.Number,
			milestone.OpenIssues,
			milestone.State,
			lib.TruncToBytes(milestone.Title, 200),
			milestone.UpdatedAt,
			ev.Actor.ID,
			maybeHide(ev.Actor.Login),
			ev.Repo.ID,
			ev.Repo.Name,
			ev.Type,
			ev.CreatedAt,
			lib.ActorLoginOrNil(milestone.Creator, maybeHide),
		}...,
	)
}

// Inserts single GHA Forkee (old format < 2015)
func ghaForkeeOld(con *sql.Tx, ctx *lib.Ctx, eid string, forkee *lib.ForkeeOld, actor *lib.Actor, repo *lib.Repo, ev *lib.EventOld, maybeHide func(string) string) {

	// Lookup author by GitHub login
	aid := lookupActorTx(con, ctx, forkee.Owner, maybeHide)

	// Owner
	owner := lib.Actor{ID: aid, Login: forkee.Owner}
	ghaActor(con, ctx, &owner, maybeHide)

	// gha_forkees
	// Table details and analysis in `analysis/analysis.txt` and `analysis/forkee_*.json`
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		"insert into gha_forkees("+
			"id, event_id, name, full_name, owner_id, description, fork, "+
			"created_at, updated_at, pushed_at, homepage, size, language, organization, "+
			"stargazers_count, has_issues, has_projects, has_downloads, "+
			"has_wiki, has_pages, forks, default_branch, open_issues, watchers, public, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_owner_login) "+lib.NValues(32),
		lib.AnyArray{
			forkee.ID,
			eid,
			lib.TruncToBytes(forkee.Name, 80),
			lib.TruncToBytes(forkee.Name, 200), // ForkeeOld has no FullName
			owner.ID,
			lib.TruncStringOrNil(forkee.Description, 0xffff),
			forkee.Fork,
			forkee.CreatedAt,
			forkee.CreatedAt, // ForkeeOld has no UpdatedAt
			lib.TimeOrNil(forkee.PushedAt),
			lib.StringOrNil(forkee.Homepage),
			forkee.Size,
			lib.StringOrNil(forkee.Language),
			lib.StringOrNil(forkee.Organization),
			forkee.Stargazers,
			forkee.HasIssues,
			nil,
			forkee.HasDownloads,
			forkee.HasWiki,
			nil,
			forkee.Forks,
			lib.TruncToBytes(forkee.DefaultBranch, 200),
			forkee.OpenIssues,
			forkee.Watchers,
			lib.NegatedBoolOrNil(forkee.Private),
			actor.ID,
			maybeHide(actor.Login),
			repo.ID,
			repo.Name,
			ev.Type,
			ev.CreatedAt,
			maybeHide(owner.Login),
		}...,
	)
}

// Inserts single GHA Forkee
func ghaForkee(con *sql.Tx, ctx *lib.Ctx, eid string, forkee *lib.Forkee, ev *lib.Event, maybeHide func(string) string) {
	// owner
	ghaActor(con, ctx, &forkee.Owner, maybeHide)

	// gha_forkees
	// Table details and analysis in `analysis/analysis.txt` and `analysis/forkee_*.json`
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		"insert into gha_forkees("+
			"id, event_id, name, full_name, owner_id, description, fork, "+
			"created_at, updated_at, pushed_at, homepage, size, language, organization, "+
			"stargazers_count, has_issues, has_projects, has_downloads, "+
			"has_wiki, has_pages, forks, default_branch, open_issues, watchers, public, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_owner_login) "+lib.NValues(32),
		lib.AnyArray{
			forkee.ID,
			eid,
			lib.TruncToBytes(forkee.Name, 80),
			lib.TruncToBytes(forkee.FullName, 200),
			forkee.Owner.ID,
			lib.TruncStringOrNil(forkee.Description, 0xffff),
			forkee.Fork,
			forkee.CreatedAt,
			forkee.UpdatedAt,
			lib.TimeOrNil(forkee.PushedAt),
			lib.StringOrNil(forkee.Homepage),
			forkee.Size,
			nil,
			nil,
			forkee.StargazersCount,
			forkee.HasIssues,
			lib.BoolOrNil(forkee.HasProjects),
			forkee.HasDownloads,
			forkee.HasWiki,
			lib.BoolOrNil(forkee.HasPages),
			forkee.Forks,
			lib.TruncToBytes(forkee.DefaultBranch, 200),
			forkee.OpenIssues,
			forkee.Watchers,
			lib.BoolOrNil(forkee.Public),
			ev.Actor.ID,
			maybeHide(ev.Actor.Login),
			ev.Repo.ID,
			ev.Repo.Name,
			ev.Type,
			ev.CreatedAt,
			maybeHide(forkee.Owner.Login),
		}...,
	)
}

// Inserts single GHA Branch
func ghaBranch(con *sql.Tx, ctx *lib.Ctx, eid string, branch *lib.Branch, ev *lib.Event, skipIDs []int, maybeHide func(string) string) {
	// user
	if branch.User != nil {
		ghaActor(con, ctx, branch.User, maybeHide)
	}

	// repo
	if branch.Repo != nil {
		rid := branch.Repo.ID
		insert := true
		for _, skipID := range skipIDs {
			if rid == skipID {
				insert = false
				break
			}
		}
		if insert {
			ghaForkee(con, ctx, eid, branch.Repo, ev, maybeHide)
		}
	}

	// gha_branches
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		"insert into gha_branches("+
			"sha, event_id, user_id, repo_id, label, ref, "+
			"dup_type, dup_created_at, dupn_user_login, dupn_forkee_name"+
			") "+lib.NValues(10),
		lib.AnyArray{
			branch.SHA,
			eid,
			lib.ActorIDOrNil(branch.User),
			lib.ForkeeIDOrNil(branch.Repo), // GitHub uses JSON "repo" but it conatins Forkee
			lib.TruncToBytes(branch.Label, 200),
			lib.TruncToBytes(branch.Ref, 200),
			ev.Type,
			ev.CreatedAt,
			lib.ActorLoginOrNil(branch.User, maybeHide),
			lib.ForkeeNameOrNil(branch.Repo),
		}...,
	)
}

// Search for given label using name & color
// If not found, return hash as its ID
func lookupLabel(con *sql.Tx, ctx *lib.Ctx, name string, color string) int {
	rows := lib.QuerySQLTxWithErr(
		con,
		ctx,
		fmt.Sprintf(
			"select id from gha_labels where name=%s and color=%s",
			lib.NValue(1),
			lib.NValue(2),
		),
		name,
		color,
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	lid := 0
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&lid))
	}
	lib.FatalOnError(rows.Err())
	if lid == 0 {
		lid = lib.HashStrings([]string{name, color})
	}
	return lid
}

// Search for given actor using his/her login
// If not found, return hash as its ID
func lookupActor(db *sql.DB, ctx *lib.Ctx, login string, maybeHide func(string) string) int {
	hlogin := maybeHide(login)
	rows := lib.QuerySQLWithErr(
		db,
		ctx,
		fmt.Sprintf("select id from gha_actors where login=%s", lib.NValue(1)),
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

// Search for given actor using his/her login
// If not found, return hash as its ID
func lookupActorTx(con *sql.Tx, ctx *lib.Ctx, login string, maybeHide func(string) string) int {
	hlogin := maybeHide(login)
	rows := lib.QuerySQLTxWithErr(
		con,
		ctx,
		fmt.Sprintf("select id from gha_actors where login=%s", lib.NValue(1)),
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

// Try to find Repo by name and Organization
func findRepoFromNameAndOrg(db *sql.DB, ctx *lib.Ctx, repoName string, orgID *int) (int, bool) {
	var rows *sql.Rows
	if orgID != nil {
		rows = lib.QuerySQLWithErr(
			db,
			ctx,
			fmt.Sprintf(
				"select id from gha_repos where name=%s and org_id=%s",
				lib.NValue(1),
				lib.NValue(2),
			),
			repoName,
			orgID,
		)
	} else {
		rows = lib.QuerySQLWithErr(
			db,
			ctx,
			fmt.Sprintf(
				"select id from gha_repos where name=%s and org_id is null",
				lib.NValue(1),
			),
			repoName,
		)
	}
	defer func() { lib.FatalOnError(rows.Close()) }()
	exists := false
	rid := 0
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&rid))
		exists = true
	}
	lib.FatalOnError(rows.Err())
	return rid, exists
}

// Try to find OrgID for given OrgLogin (returns nil for nil)
func findOrgIDOrNil(db *sql.DB, ctx *lib.Ctx, orgLogin *string) *int {
	var orgID int
	if orgLogin == nil {
		return nil
	}
	rows := lib.QuerySQLWithErr(
		db,
		ctx,
		fmt.Sprintf(
			"select id from gha_orgs where login=%s",
			lib.NValue(1),
		),
		*orgLogin,
	)
	defer func() { lib.FatalOnError(rows.Close()) }()
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&orgID))
		return &orgID
	}
	lib.FatalOnError(rows.Err())
	return nil
}

// Check if given event existis (given by ID)
func eventExists(db *sql.DB, ctx *lib.Ctx, eventID string) bool {
	rows := lib.QuerySQLWithErr(db, ctx, fmt.Sprintf("select 1 from gha_events where id=%s", lib.NValue(1)), eventID)
	defer func() { lib.FatalOnError(rows.Close()) }()
	exists := false
	for rows.Next() {
		exists = true
	}
	return exists
}

// Process GHA pages
// gha_pages
// {"page_name:String"=>370, "title:String"=>370, "summary:NilClass"=>370,
// "action:String"=>370, "sha:String"=>370, "html_url:String"=>370}
// {"page_name"=>65, "title"=>65, "summary"=>0, "action"=>7, "sha"=>40, "html_url"=>130}
// 370
func ghaPages(con *sql.Tx, ctx *lib.Ctx, payloadPages *[]lib.Page, eventID string, actor *lib.Actor, repo *lib.Repo, eType string, eCreatedAt time.Time, maybeHide func(string) string) {
	pages := []lib.Page{}
	if payloadPages != nil {
		pages = *payloadPages
	}
	for _, page := range pages {
		sha := page.SHA
		lib.ExecSQLTxWithErr(
			con,
			ctx,
			lib.InsertIgnore(
				"into gha_pages(sha, event_id, action, title, "+
					"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
					") "+lib.NValues(10)),
			lib.AnyArray{
				sha,
				eventID,
				page.Action,
				lib.TruncToBytes(page.Title, 300),
				actor.ID,
				maybeHide(actor.Login),
				repo.ID,
				repo.Name,
				eType,
				eCreatedAt,
			}...,
		)
	}
}

// gha_comments
// Table details and analysis in `analysis/analysis.txt` and `analysis/comment_*.json`
func ghaComment(con *sql.Tx, ctx *lib.Ctx, payloadComment *lib.Comment, eventID string, actor *lib.Actor, repo *lib.Repo, eType string, eCreatedAt time.Time, maybeHide func(string) string) {
	if payloadComment == nil {
		return
	}
	comment := *payloadComment

	// user
	ghaActor(con, ctx, &comment.User, maybeHide)

	// comment
	cid := comment.ID
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		lib.InsertIgnore(
			"into gha_comments("+
				"id, event_id, body, created_at, updated_at, user_id, "+
				"commit_id, original_commit_id, diff_hunk, position, "+
				"original_position, path, pull_request_review_id, line, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
				"dup_user_login) "+lib.NValues(21),
		),
		lib.AnyArray{
			cid,
			eventID,
			lib.TruncToBytes(comment.Body, 0xffff),
			comment.CreatedAt,
			comment.UpdatedAt,
			comment.User.ID,
			lib.StringOrNil(comment.CommitID),
			lib.StringOrNil(comment.OriginalCommitID),
			lib.StringOrNil(comment.DiffHunk),
			lib.IntOrNil(comment.Position),
			lib.IntOrNil(comment.OriginalPosition),
			lib.StringOrNil(comment.Path),
			lib.IntOrNil(comment.PullRequestReviewID),
			lib.IntOrNil(comment.Line),
			actor.ID,
			maybeHide(actor.Login),
			repo.ID,
			repo.Name,
			eType,
			eCreatedAt,
			maybeHide(comment.User.Login),
		}...,
	)
}

// gha_releases
// Table details and analysis in `analysis/analysis.txt` and `analysis/release_*.json`
func ghaRelease(con *sql.Tx, ctx *lib.Ctx, payloadRelease *lib.Release, eventID string, actor *lib.Actor, repo *lib.Repo, eType string, eCreatedAt time.Time, maybeHide func(string) string) {
	if payloadRelease == nil {
		return
	}
	release := *payloadRelease

	// author
	ghaActor(con, ctx, &release.Author, maybeHide)

	// release
	rid := release.ID
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		"insert into gha_releases("+
			"id, event_id, tag_name, target_commitish, name, draft, "+
			"author_id, prerelease, created_at, published_at, body, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_author_login) "+lib.NValues(18),
		lib.AnyArray{
			rid,
			eventID,
			lib.TruncToBytes(release.TagName, 200),
			lib.TruncToBytes(release.TargetCommitish, 200),
			lib.TruncStringOrNil(release.Name, 200),
			release.Draft,
			release.Author.ID,
			release.Prerelease,
			release.CreatedAt,
			lib.TimeOrNil(release.PublishedAt),
			lib.TruncStringOrNil(release.Body, 0xffff),
			actor.ID,
			maybeHide(actor.Login),
			repo.ID,
			repo.Name,
			eType,
			eCreatedAt,
			maybeHide(release.Author.Login),
		}...,
	)

	// Assets
	for _, asset := range release.Assets {
		// uploader
		ghaActor(con, ctx, &asset.Uploader, maybeHide)

		// asset
		aid := asset.ID
		lib.ExecSQLTxWithErr(
			con,
			ctx,
			"insert into gha_assets("+
				"id, event_id, name, label, uploader_id, content_type, "+
				"state, size, download_count, created_at, updated_at, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
				"dup_uploader_login) "+lib.NValues(18),
			lib.AnyArray{
				aid,
				eventID,
				lib.TruncToBytes(asset.Name, 200),
				lib.TruncStringOrNil(asset.Label, 120),
				asset.Uploader.ID,
				asset.ContentType,
				asset.State,
				asset.Size,
				asset.DownloadCount,
				asset.CreatedAt,
				asset.UpdatedAt,
				actor.ID,
				maybeHide(actor.Login),
				repo.ID,
				repo.Name,
				eType,
				eCreatedAt,
				maybeHide(asset.Uploader.Login),
			}...,
		)

		// release-asset connection
		lib.ExecSQLTxWithErr(
			con,
			ctx,
			"insert into gha_releases_assets(release_id, event_id, asset_id) "+lib.NValues(3),
			lib.AnyArray{rid, eventID, aid}...,
		)
	}
}

// gha_pull_requests
// Table details and analysis in `analysis/analysis.txt` and `analysis/pull_request_*.json`
func ghaPullRequest(con *sql.Tx, ctx *lib.Ctx, payloadPullRequest *lib.PullRequest, eventID string, actor *lib.Actor, repo *lib.Repo, eType string, eCreatedAt time.Time, forkeeIDsToSkip []int, maybeHide func(string) string) {
	if payloadPullRequest == nil {
		return
	}

	// PR object
	pr := *payloadPullRequest

	// user
	ghaActor(con, ctx, &pr.User, maybeHide)

	baseSHA := pr.Base.SHA
	headSHA := pr.Head.SHA
	baseRepoID := lib.ForkeeIDOrNil(pr.Base.Repo)

	// Create Event
	ev := lib.Event{Actor: *actor, Repo: *repo, Type: eType, CreatedAt: eCreatedAt}

	// base
	ghaBranch(con, ctx, eventID, &pr.Base, &ev, forkeeIDsToSkip, maybeHide)

	// head (if different, and skip its repo if defined and the same as base repo)
	if baseSHA != headSHA {
		if baseRepoID != nil {
			forkeeIDsToSkip = append(forkeeIDsToSkip, baseRepoID.(int))
		}
		ghaBranch(con, ctx, eventID, &pr.Head, &ev, forkeeIDsToSkip, maybeHide)
	}

	// merged_by
	if pr.MergedBy != nil {
		ghaActor(con, ctx, pr.MergedBy, maybeHide)
	}

	// assignee
	if pr.Assignee != nil {
		ghaActor(con, ctx, pr.Assignee, maybeHide)
	}

	// milestone
	if pr.Milestone != nil {
		ghaMilestone(con, ctx, eventID, pr.Milestone, &ev, maybeHide)
	}

	// pull_request
	prid := pr.ID
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		"insert into gha_pull_requests("+
			"id, event_id, user_id, base_sha, head_sha, merged_by_id, assignee_id, milestone_id, "+
			"number, state, locked, title, body, created_at, updated_at, closed_at, merged_at, "+
			"merge_commit_sha, merged, mergeable, rebaseable, mergeable_state, comments, "+
			"review_comments, maintainer_can_modify, commits, additions, deletions, changed_files, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
			"dup_user_login, dupn_assignee_login, dupn_merged_by_login) "+lib.NValues(38),
		lib.AnyArray{
			prid,
			eventID,
			pr.User.ID,
			baseSHA,
			headSHA,
			lib.ActorIDOrNil(pr.MergedBy),
			lib.ActorIDOrNil(pr.Assignee),
			lib.MilestoneIDOrNil(pr.Milestone),
			pr.Number,
			pr.State,
			lib.BoolOrNil(pr.Locked),
			pr.Title,
			lib.TruncStringOrNil(pr.Body, 0xffff),
			pr.CreatedAt,
			pr.UpdatedAt,
			lib.TimeOrNil(pr.ClosedAt),
			lib.TimeOrNil(pr.MergedAt),
			lib.StringOrNil(pr.MergeCommitSHA),
			lib.BoolOrNil(pr.Merged),
			lib.BoolOrNil(pr.Mergeable),
			lib.BoolOrNil(pr.Rebaseable),
			lib.StringOrNil(pr.MergeableState),
			lib.IntOrNil(pr.Comments),
			lib.IntOrNil(pr.ReviewComments),
			lib.BoolOrNil(pr.MaintainerCanModify),
			lib.IntOrNil(pr.Commits),
			lib.IntOrNil(pr.Additions),
			lib.IntOrNil(pr.Deletions),
			lib.IntOrNil(pr.ChangedFiles),
			actor.ID,
			maybeHide(actor.Login),
			repo.ID,
			repo.Name,
			eType,
			eCreatedAt,
			maybeHide(pr.User.Login),
			lib.ActorLoginOrNil(pr.Assignee, maybeHide),
			lib.ActorLoginOrNil(pr.MergedBy, maybeHide),
		}...,
	)

	// Arrays: actors: assignees, requested_reviewers
	// assignees
	var assignees []lib.Actor

	prAid := lib.ActorIDOrNil(pr.Assignee)
	if pr.Assignee != nil {
		assignees = append(assignees, *pr.Assignee)
	}

	if pr.Assignees != nil {
		for _, assignee := range *pr.Assignees {
			aid := assignee.ID
			if aid == prAid {
				continue
			}
			assignees = append(assignees, assignee)
		}
	}

	for _, assignee := range assignees {
		// assignee
		ghaActor(con, ctx, &assignee, maybeHide)

		// pull_request-assignee connection
		lib.ExecSQLTxWithErr(
			con,
			ctx,
			"insert into gha_pull_requests_assignees(pull_request_id, event_id, assignee_id) "+lib.NValues(3),
			lib.AnyArray{prid, eventID, assignee.ID}...,
		)
	}

	// requested_reviewers
	if pr.RequestedReviewers != nil {
		for _, reviewer := range *pr.RequestedReviewers {
			// reviewer
			ghaActor(con, ctx, &reviewer, maybeHide)

			// pull_request-requested_reviewer connection
			lib.ExecSQLTxWithErr(
				con,
				ctx,
				"insert into gha_pull_requests_requested_reviewers(pull_request_id, event_id, requested_reviewer_id) "+lib.NValues(3),
				lib.AnyArray{prid, eventID, reviewer.ID}...,
			)
		}
	}
}

// gha_teams
func ghaTeam(con *sql.Tx, ctx *lib.Ctx, payloadTeam *lib.Team, payloadRepo *lib.Forkee, eventID string, actor *lib.Actor, repo *lib.Repo, eType string, eCreatedAt time.Time, maybeHide func(string) string) {
	if payloadTeam == nil {
		return
	}
	team := *payloadTeam

	// team
	tid := team.ID
	lib.ExecSQLTxWithErr(
		con,
		ctx,
		"insert into gha_teams("+
			"id, event_id, name, slug, permission, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
			") "+lib.NValues(11),
		lib.AnyArray{
			tid,
			eventID,
			lib.TruncToBytes(team.Name, 120),
			lib.TruncToBytes(team.Slug, 100),
			lib.TruncToBytes(team.Permission, 20),
			actor.ID,
			maybeHide(actor.Login),
			repo.ID,
			repo.Name,
			eType,
			eCreatedAt,
		}...,
	)

	// team-repository connection
	if payloadRepo != nil {
		lib.ExecSQLTxWithErr(
			con,
			ctx,
			"insert into gha_teams_repositories(team_id, event_id, repository_id) "+lib.NValues(3),
			lib.AnyArray{tid, eventID, payloadRepo.ID}...,
		)
	}
}

// Write GHA entire event (in old pre 2015 format) into Postgres DB
func writeToDBOldFmt(db *sql.DB, ctx *lib.Ctx, eventID string, ev *lib.EventOld, shas map[string]string) int {
	if eventExists(db, ctx, eventID) {
		return 0
	}

	// To handle GDPR
	maybeHide := lib.MaybeHideFunc(shas)

	// Lookup author by GitHub login
	aid := lookupActor(db, ctx, ev.Actor, maybeHide)
	actor := lib.Actor{ID: aid, Login: ev.Actor}

	// Repository
	repository := ev.Repository

	// Find Org ID from Repository.Organization
	oid := findOrgIDOrNil(db, ctx, repository.Organization)

	// Find Repo ID from Repository (this is a ForkeeOld before 2015).
	rid, ok := findRepoFromNameAndOrg(db, ctx, repository.Name, oid)
	if !ok {
		rid = repository.ID
	}

	// We defer transaction create until we're inserting data that can be shared between different events
	lib.ExecSQLWithErr(
		db,
		ctx,
		"insert into gha_events("+
			"id, type, actor_id, repo_id, public, created_at, "+
			"dup_actor_login, dup_repo_name, org_id, forkee_id) "+lib.NValues(10),
		lib.AnyArray{
			eventID,
			ev.Type,
			aid,
			rid,
			ev.Public,
			ev.CreatedAt,
			maybeHide(ev.Actor),
			ev.Repository.Name,
			oid,
			ev.Repository.ID,
		}...,
	)

	// Organization
	if repository.Organization != nil {
		if oid == nil {
			h := lib.HashStrings([]string{*repository.Organization})
			oid = &h
		}
		ghaOrg(db, ctx, &lib.Org{ID: *oid, Login: *repository.Organization})
	}

	// Add Repository
	repo := lib.Repo{ID: rid, Name: repository.Name}
	ghaRepo(db, ctx, &repo, oid, repository.Organization)

	// Pre 2015 Payload
	pl := ev.Payload
	if pl == nil {
		return 0
	}

	iid := lib.FirstIntOrNil([]*int{pl.Issue, pl.IssueID})
	cid := lib.CommentIDOrNil(pl.Comment)
	if cid == nil {
		cid = lib.IntOrNil(pl.CommentID)
	}

	lib.ExecSQLWithErr(
		db,
		ctx,
		"insert into gha_payloads("+
			"event_id, push_id, size, ref, head, befor, action, "+
			"issue_id, pull_request_id, comment_id, ref_type, master_branch, commit, "+
			"description, number, forkee_id, release_id, member_id, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
			") "+lib.NValues(24),
		lib.AnyArray{
			eventID,
			nil,
			lib.IntOrNil(pl.Size),
			lib.TruncStringOrNil(pl.Ref, 200),
			lib.StringOrNil(pl.Head),
			nil,
			lib.StringOrNil(pl.Action),
			iid,
			lib.PullRequestIDOrNil(pl.PullRequest),
			cid,
			lib.StringOrNil(pl.RefType),
			lib.TruncStringOrNil(pl.MasterBranch, 200),
			lib.StringOrNil(pl.Commit),
			lib.TruncStringOrNil(pl.Description, 0xffff),
			lib.IntOrNil(pl.Number),
			lib.ForkeeIDOrNil(pl.Repository),
			lib.ReleaseIDOrNil(pl.Release),
			lib.ActorIDOrNil(pl.Member),
			actor.ID,
			maybeHide(actor.Login),
			repo.ID,
			repo.Name,
			ev.Type,
			ev.CreatedAt,
		}...,
	)

	// Start transaction for data possibly shared between events
	con, err := db.Begin()
	lib.FatalOnError(err)

	// gha_actors
	ghaActor(con, ctx, &actor, maybeHide)

	// Payload's Forkee (it uses new structure, so I'm giving it precedence over
	// Event's Forkee (which uses older structure)
	if pl.Repository != nil {
		// Reposotory is actually a Forkee (non old in this case!)
		// Artificial event is only used to allow duplicating EventOld's data
		// (passed as Event to avoid code duplication)
		artificialEv := lib.Event{Actor: actor, Repo: repo, Type: ev.Type, CreatedAt: ev.CreatedAt}
		ghaForkee(con, ctx, eventID, pl.Repository, &artificialEv, maybeHide)
	}

	// Add Forkee in old mode if we didn't added it from payload or if it is a different Forkee
	if pl.Repository == nil || pl.Repository.ID != ev.Repository.ID {
		ghaForkeeOld(con, ctx, eventID, &ev.Repository, &actor, &repo, ev, maybeHide)
	}

	// SHAs - commits
	if pl.SHAs != nil {
		commits := *pl.SHAs
		for _, comm := range commits {
			commit, ok := comm.([]interface{})
			if !ok {
				lib.Fatalf("comm is not []interface{}: %+v", comm)
			}
			sha, ok := commit[0].(string)
			if !ok {
				lib.Fatalf("commit[0] is not string: %+v", commit[0])
			}
			lib.ExecSQLTxWithErr(
				con,
				ctx,
				"insert into gha_commits("+
					"sha, event_id, author_name, encrypted_email, message, is_distinct, "+
					"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
					") "+lib.NValues(12),
				lib.AnyArray{
					sha,
					eventID,
					maybeHide(lib.TruncToBytes(commit[3].(string), 160)),
					// TODO: FIXME: change when past data is received
					lib.TruncToBytes(commit[3].(string), 160),
					//lib.TruncToBytes(commit[1].(string), 160),
					// TODO: FIXME: change when past data is received
					lib.TruncToBytes(commit[2].(string), 0xffff),
					commit[4].(bool),
					actor.ID,
					maybeHide(actor.Login),
					repo.ID,
					repo.Name,
					ev.Type,
					ev.CreatedAt,
				}...,
			)
		}
	}

	// Pages
	ghaPages(con, ctx, pl.Pages, eventID, &actor, &repo, ev.Type, ev.CreatedAt, maybeHide)

	// Member
	if pl.Member != nil {
		ghaActor(con, ctx, pl.Member, maybeHide)
	}

	// Comment
	ghaComment(con, ctx, pl.Comment, eventID, &actor, &repo, ev.Type, ev.CreatedAt, maybeHide)

	// Release & assets
	ghaRelease(con, ctx, pl.Release, eventID, &actor, &repo, ev.Type, ev.CreatedAt, maybeHide)

	// Team & Repo connection
	ghaTeam(con, ctx, pl.Team, pl.Repository, eventID, &actor, &repo, ev.Type, ev.CreatedAt, maybeHide)

	// Pull Request
	forkeeIDsToSkip := []int{ev.Repository.ID}
	if pl.Repository != nil {
		forkeeIDsToSkip = append(forkeeIDsToSkip, pl.Repository.ID)
	}
	ghaPullRequest(con, ctx, pl.PullRequest, eventID, &actor, &repo, ev.Type, ev.CreatedAt, forkeeIDsToSkip, maybeHide)

	// We need artificial issue
	// gha_issues
	// Table details and analysis in `analysis/analysis.txt` and `analysis/issue_*.json`
	if pl.PullRequest != nil {
		pr := *pl.PullRequest

		// issue
		iid = -pr.ID
		isPR := true
		comments := 0
		locked := false
		if pr.Comments != nil {
			comments = *pr.Comments
		}
		if pr.Locked != nil {
			locked = *pr.Locked
		}
		lib.ExecSQLTxWithErr(
			con,
			ctx,
			"insert into gha_issues("+
				"id, event_id, assignee_id, body, closed_at, comments, created_at, "+
				"locked, milestone_id, number, state, title, updated_at, user_id, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
				"dup_user_login, dupn_assignee_login, is_pull_request) "+lib.NValues(23),
			lib.AnyArray{
				iid,
				eventID,
				lib.ActorIDOrNil(pr.Assignee),
				lib.TruncStringOrNil(pr.Body, 0xffff),
				lib.TimeOrNil(pr.ClosedAt),
				comments,
				pr.CreatedAt,
				locked,
				lib.MilestoneIDOrNil(pr.Milestone),
				pr.Number,
				pr.State,
				pr.Title,
				pr.UpdatedAt,
				pr.User.ID,
				actor.ID,
				maybeHide(actor.Login),
				repo.ID,
				repo.Name,
				ev.Type,
				ev.CreatedAt,
				maybeHide(pr.User.Login),
				lib.ActorLoginOrNil(pr.Assignee, maybeHide),
				isPR,
			}...,
		)

		var assignees []lib.Actor

		prAid := lib.ActorIDOrNil(pr.Assignee)
		if pr.Assignee != nil {
			assignees = append(assignees, *pr.Assignee)
		}

		if pr.Assignees != nil {
			for _, assignee := range *pr.Assignees {
				aid := assignee.ID
				if aid == prAid {
					continue
				}
				assignees = append(assignees, assignee)
			}
		}

		for _, assignee := range assignees {
			// pull_request-assignee connection
			lib.ExecSQLTxWithErr(
				con,
				ctx,
				"insert into gha_issues_assignees(issue_id, event_id, assignee_id) "+lib.NValues(3),
				lib.AnyArray{iid, eventID, assignee.ID}...,
			)
		}
	}

	// Final commit
	lib.FatalOnError(con.Commit())
	return 1
}

// Write entire GHA event (in a new 2015+ format) into Postgres DB
func writeToDB(db *sql.DB, ctx *lib.Ctx, ev *lib.Event, shas map[string]string) int {
	eventID := ev.ID
	if eventExists(db, ctx, eventID) {
		return 0
	}

	// To handle GDPR
	maybeHide := lib.MaybeHideFunc(shas)

	// We defer transaction create until we're inserting data that can be shared between different events
	// gha_events
	// {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592,
	// "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592,
	// "org:Hash"=>19451}
	// {"id"=>10, "type"=>29, "actor"=>278, "repo"=>290, "payload"=>216017, "public"=>4,
	// "created_at"=>20, "org"=>230}
	// Fields dup_actor_login, dup_repo_name are copied from (gha_actors and gha_repos) to save
	// joins on complex queries (MySQL has no hash joins and is very slow on big tables joins)
	lib.ExecSQLWithErr(
		db,
		ctx,
		"insert into gha_events("+
			"id, type, actor_id, repo_id, public, created_at, "+
			"dup_actor_login, dup_repo_name, org_id, forkee_id) "+lib.NValues(10),
		lib.AnyArray{
			eventID,
			ev.Type,
			ev.Actor.ID,
			ev.Repo.ID,
			ev.Public,
			ev.CreatedAt,
			maybeHide(ev.Actor.Login),
			ev.Repo.Name,
			lib.OrgIDOrNil(ev.Org),
			nil,
		}...,
	)

	// Repository
	repo := ev.Repo
	org := ev.Org
	ghaRepo(db, ctx, &repo, lib.OrgIDOrNil(org), lib.OrgLoginOrNil(org))

	// Organization
	if org != nil {
		ghaOrg(db, ctx, org)
	}

	// gha_payloads
	// {"push_id:Fixnum"=>24636, "size:Fixnum"=>24636, "distinct_size:Fixnum"=>24636,
	// "ref:String"=>30522, "head:String"=>24636, "before:String"=>24636, "commits:Array"=>24636,
	// "action:String"=>14317, "issue:Hash"=>6446, "comment:Hash"=>6055, "ref_type:String"=>8010,
	// "master_branch:String"=>6724, "description:String"=>3701, "pusher_type:String"=>8010,
	// "pull_request:Hash"=>4475, "ref:NilClass"=>2124, "description:NilClass"=>3023,
	// "number:Fixnum"=>2992, "forkee:Hash"=>1211, "pages:Array"=>370, "release:Hash"=>156,
	// "member:Hash"=>219}
	// {"push_id"=>10, "size"=>4, "distinct_size"=>4, "ref"=>110, "head"=>40, "before"=>40,
	// "commits"=>33215, "action"=>9, "issue"=>87776, "comment"=>177917, "ref_type"=>10,
	// "master_branch"=>34, "description"=>3222, "pusher_type"=>4, "pull_request"=>70565,
	// "number"=>5, "forkee"=>6880, "pages"=>855, "release"=>31206, "member"=>1040}
	// 48746
	// using exec_stmt (without select), because payload are per event_id.
	// Columns duplicated from gha_events starts with "dup_"
	pl := ev.Payload
	lib.ExecSQLWithErr(
		db,
		ctx,
		"insert into gha_payloads("+
			"event_id, push_id, size, ref, head, befor, action, "+
			"issue_id, pull_request_id, comment_id, ref_type, master_branch, commit, "+
			"description, number, forkee_id, release_id, member_id, "+
			"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
			") "+lib.NValues(24),
		lib.AnyArray{
			eventID,
			lib.IntOrNil(pl.PushID),
			lib.IntOrNil(pl.Size),
			lib.TruncStringOrNil(pl.Ref, 200),
			lib.StringOrNil(pl.Head),
			lib.StringOrNil(pl.Before),
			lib.StringOrNil(pl.Action),
			lib.IssueIDOrNil(pl.Issue),
			lib.PullRequestIDOrNil(pl.PullRequest),
			lib.CommentIDOrNil(pl.Comment),
			lib.StringOrNil(pl.RefType),
			lib.TruncStringOrNil(pl.MasterBranch, 200),
			nil,
			lib.TruncStringOrNil(pl.Description, 0xffff),
			lib.IntOrNil(pl.Number),
			lib.ForkeeIDOrNil(pl.Forkee),
			lib.ReleaseIDOrNil(pl.Release),
			lib.ActorIDOrNil(pl.Member),
			ev.Actor.ID,
			maybeHide(ev.Actor.Login),
			ev.Repo.ID,
			ev.Repo.Name,
			ev.Type,
			ev.CreatedAt,
		}...,
	)

	// Start transaction for data possibly shared between events
	con, err := db.Begin()
	lib.FatalOnError(err)

	// gha_actors
	ghaActor(con, ctx, &ev.Actor, maybeHide)

	// gha_commits
	// {"sha:String"=>23265, "author:Hash"=>23265, "message:String"=>23265,
	// "distinct:TrueClass"=>21789, "url:String"=>23265, "distinct:FalseClass"=>1476}
	// {"sha"=>40, "author"=>177, "message"=>19005, "distinct"=>5, "url"=>191}
	// author: {"name:String"=>23265, "email:String"=>23265} (only git username/email)
	// author: {"name"=>96, "email"=>95}
	// 23265
	commits := []lib.Commit{}
	if pl.Commits != nil {
		commits = *pl.Commits
	}
	for _, commit := range commits {
		sha := commit.SHA
		lib.ExecSQLTxWithErr(
			con,
			ctx,
			"insert into gha_commits("+
				"sha, event_id, author_name, encrypted_email, message, is_distinct, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at"+
				") "+lib.NValues(12),
			lib.AnyArray{
				sha,
				eventID,
				maybeHide(lib.TruncToBytes(commit.Author.Name, 160)),
				// TODO: FIXME: change when past data is received
				lib.TruncToBytes(commit.Author.Name, 160),
				//lib.TruncToBytes(commit.Author.Email, 160),
				// TODO: FIXME: change when past data is received
				lib.TruncToBytes(commit.Message, 0xffff),
				commit.Distinct,
				ev.Actor.ID,
				maybeHide(ev.Actor.Login),
				ev.Repo.ID,
				ev.Repo.Name,
				ev.Type,
				ev.CreatedAt,
			}...,
		)
	}

	// Pages
	ghaPages(con, ctx, pl.Pages, eventID, &ev.Actor, &ev.Repo, ev.Type, ev.CreatedAt, maybeHide)

	// Member
	if pl.Member != nil {
		ghaActor(con, ctx, pl.Member, maybeHide)
	}

	// Comment
	ghaComment(con, ctx, pl.Comment, eventID, &ev.Actor, &ev.Repo, ev.Type, ev.CreatedAt, maybeHide)

	// gha_issues
	// Table details and analysis in `analysis/analysis.txt` and `analysis/issue_*.json`
	if pl.Issue != nil {
		issue := *pl.Issue

		// user, assignee
		ghaActor(con, ctx, &issue.User, maybeHide)
		if issue.Assignee != nil {
			ghaActor(con, ctx, issue.Assignee, maybeHide)
		}

		// issue
		iid := issue.ID
		isPR := false
		if issue.PullRequest != nil {
			isPR = true
		}
		lib.ExecSQLTxWithErr(
			con,
			ctx,
			"insert into gha_issues("+
				"id, event_id, assignee_id, body, closed_at, comments, created_at, "+
				"locked, milestone_id, number, state, title, updated_at, user_id, "+
				"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
				"dup_user_login, dupn_assignee_login, is_pull_request) "+lib.NValues(23),
			lib.AnyArray{
				iid,
				eventID,
				lib.ActorIDOrNil(issue.Assignee),
				lib.TruncStringOrNil(issue.Body, 0xffff),
				lib.TimeOrNil(issue.ClosedAt),
				issue.Comments,
				issue.CreatedAt,
				issue.Locked,
				lib.MilestoneIDOrNil(issue.Milestone),
				issue.Number,
				issue.State,
				issue.Title,
				issue.UpdatedAt,
				issue.User.ID,
				ev.Actor.ID,
				maybeHide(ev.Actor.Login),
				ev.Repo.ID,
				ev.Repo.Name,
				ev.Type,
				ev.CreatedAt,
				maybeHide(issue.User.Login),
				lib.ActorLoginOrNil(issue.Assignee, maybeHide),
				isPR,
			}...,
		)

		// milestone
		if issue.Milestone != nil {
			ghaMilestone(con, ctx, eventID, issue.Milestone, ev, maybeHide)
		}

		pAid := lib.ActorIDOrNil(issue.Assignee)
		for _, assignee := range issue.Assignees {
			aid := assignee.ID
			if aid == pAid {
				continue
			}

			// assignee
			ghaActor(con, ctx, &assignee, maybeHide)

			// issue-assignee connection
			lib.ExecSQLTxWithErr(
				con,
				ctx,
				"insert into gha_issues_assignees(issue_id, event_id, assignee_id) "+lib.NValues(3),
				lib.AnyArray{iid, eventID, aid}...,
			)
		}

		// labels
		for _, label := range issue.Labels {
			lid := lib.IntOrNil(label.ID)
			if lid == nil {
				lid = lookupLabel(con, ctx, lib.TruncToBytes(label.Name, 160), label.Color)
			}

			// label
			lib.ExecSQLTxWithErr(
				con,
				ctx,
				lib.InsertIgnore("into gha_labels(id, name, color, is_default) "+lib.NValues(4)),
				lib.AnyArray{lid, lib.TruncToBytes(label.Name, 160), label.Color, lib.BoolOrNil(label.Default)}...,
			)

			// issue-label connection
			lib.ExecSQLTxWithErr(
				con,
				ctx,
				lib.InsertIgnore(
					"into gha_issues_labels(issue_id, event_id, label_id, "+
						"dup_actor_id, dup_actor_login, dup_repo_id, dup_repo_name, dup_type, dup_created_at, "+
						"dup_issue_number, dup_label_name"+
						") "+lib.NValues(11)),
				lib.AnyArray{
					iid,
					eventID,
					lid,
					ev.Actor.ID,
					maybeHide(ev.Actor.Login),
					ev.Repo.ID,
					ev.Repo.Name,
					ev.Type,
					ev.CreatedAt,
					issue.Number,
					label.Name,
				}...,
			)
		}
	}

	// gha_forkees
	if pl.Forkee != nil {
		ghaForkee(con, ctx, eventID, pl.Forkee, ev, maybeHide)
	}

	// Release & assets
	ghaRelease(con, ctx, pl.Release, eventID, &ev.Actor, &ev.Repo, ev.Type, ev.CreatedAt, maybeHide)

	// Pull Request
	ghaPullRequest(con, ctx, pl.PullRequest, eventID, &ev.Actor, &ev.Repo, ev.Type, ev.CreatedAt, []int{}, maybeHide)

	// Final commit
	lib.FatalOnError(con.Commit())
	return 1
}

// parseJSON - parse signle GHA JSON event
func parseJSON(con *sql.DB, ctx *lib.Ctx, idx, njsons int, jsonStr []byte, dt time.Time, forg, frepo map[string]struct{}, shas map[string]string) (f int, e int) {
	var (
		h         lib.Event
		hOld      lib.EventOld
		err       error
		fullName  string
		eid       string
		actorName string
	)
	if ctx.OldFormat {
		err = json.Unmarshal(jsonStr, &hOld)
	} else {
		err = json.Unmarshal(jsonStr, &h)
	}
	// jsonStr = bytes.Replace(jsonStr, []byte("\x00"), []byte(""), -1)
	if err != nil {
		ofn := fmt.Sprintf("jsons/error_%v-%d-%d.json", lib.ToGHADate(dt), idx+1, njsons)
		lib.FatalOnError(ioutil.WriteFile(ofn, jsonStr, 0644))
		lib.Printf("%v: Cannot unmarshal:\n%s\n%v\n", dt, string(jsonStr), err)
		fmt.Fprintf(os.Stderr, "%v: Cannot unmarshal:\n%s\n%v\n", dt, string(jsonStr), err)
		if ctx.AllowBrokenJSON {
			return
		}
		pretty := lib.PrettyPrintJSON(jsonStr)
		lib.Printf("%v: JSON Unmarshal failed for:\n'%v'\n", dt, string(pretty))
		fmt.Fprintf(os.Stderr, "%v: JSON Unmarshal failed for:\n'%v'\n", dt, string(pretty))
	}
	lib.FatalOnError(err)
	if ctx.OldFormat {
		fullName = lib.MakeOldRepoName(&hOld.Repository)
		actorName = hOld.Actor
	} else {
		fullName = h.Repo.Name
		actorName = h.Actor.Login
	}
	if lib.RepoHit(ctx, fullName, forg, frepo) && lib.ActorHit(ctx, actorName) {
		if ctx.OldFormat {
			eid = fmt.Sprintf("%v", lib.HashStrings([]string{hOld.Type, hOld.Actor, hOld.Repository.Name, lib.ToYMDHMSDate(hOld.CreatedAt)}))
		} else {
			eid = h.ID
		}
		if ctx.JSONOut {
			// We want to Unmarshal/Marshall ALL JSON data, regardless of what is defined in lib.Event
			pretty := lib.PrettyPrintJSON(jsonStr)
			ofn := fmt.Sprintf("jsons/%v_%v.json", dt.Unix(), eid)
			lib.FatalOnError(ioutil.WriteFile(ofn, pretty, 0644))
		}
		if ctx.DBOut {
			if ctx.OldFormat {
				e = writeToDBOldFmt(con, ctx, eid, &hOld, shas)
			} else {
				e = writeToDB(con, ctx, &h, shas)
			}
		}
		if ctx.Debug >= 1 {
			lib.Printf("Processed: '%v' event: %v\n", dt, eid)
		}
		f = 1
	}
	return
}

// markAsProcessed mark maximum processed date
func markAsProcessed(con *sql.DB, ctx *lib.Ctx, dt time.Time) {
	if !ctx.DBOut {
		return
	}
	lib.ExecSQLWithErr(
		con,
		ctx,
		lib.InsertIgnore("into gha_parsed(dt) values("+lib.NValue(1)+")"),
		dt,
	)
}

// getGHAJSON - This is a work for single go routine - 1 hour of GHA data
// Usually such JSON conatin about 15000 - 60000 singe GHA events
// Boolean channel `ch` is used to synchronize go routines
func getGHAJSON(ch chan bool, ctx *lib.Ctx, dt time.Time, forg map[string]struct{}, frepo map[string]struct{}, shas map[string]string) {
	lib.Printf("Working on %v\n", dt)

	// Connect to Postgres DB
	con := lib.PgConn(ctx)
	defer func() { lib.FatalOnError(con.Close()) }()

	fn := fmt.Sprintf("http://data.gharchive.org/%s.json.gz", lib.ToGHADate(dt))

	// Get gzipped JSON array via HTTP
	response, err := http.Get(fn)
	if err != nil {
		lib.Printf("%v: Error http.Get:\n%v\n", dt, err)
		fmt.Fprintf(os.Stderr, "%v: Error http.Get:\n%v\n", dt, err)
	}
	lib.FatalOnError(err)
	defer func() { _ = response.Body.Close() }()

	// Decompress Gzipped response
	reader, err := gzip.NewReader(response.Body)
	//lib.FatalOnError(err)
	if err != nil {
		lib.Printf("%v: No data yet, gzip reader:\n%v\n", dt, err)
		fmt.Fprintf(os.Stderr, "%v: No data yet, gzip reader:\n%v\n", dt, err)
		if ch != nil {
			ch <- true
		}
		return
	}
	lib.Printf("Opened %s\n", fn)
	defer func() { _ = reader.Close() }()

	jsonsBytes, err := ioutil.ReadAll(reader)
	//lib.FatalOnError(err)
	if err != nil {
		lib.Printf("%v: Error (no data yet, ioutil readall):\n%v\n", dt, err)
		fmt.Fprintf(os.Stderr, "%v: Error (no data yet, ioutil readall):\n%v\n", dt, err)
		if ch != nil {
			ch <- true
		}
		return
	}
	lib.Printf("Decompressed %s\n", fn)

	// Split JSON array into separate JSONs
	jsonsArray := bytes.Split(jsonsBytes, []byte("\n"))
	lib.Printf("Split %s, %d JSONs\n", fn, len(jsonsArray))

	// Process JSONs one by one
	n, f, e := 0, 0, 0
	njsons := len(jsonsArray)
	for i, json := range jsonsArray {
		if len(json) < 1 {
			continue
		}
		fi, ei := parseJSON(con, ctx, i, njsons, json, dt, forg, frepo, shas)
		n++
		f += fi
		e += ei
	}
	lib.Printf(
		"Parsed: %s: %d JSONs, found %d matching, events %d\n",
		fn, n, f, e,
	)
	// Mark date as computed, to skip fetching this JSON again when it contains no events for a current project
	markAsProcessed(con, ctx, dt)
	if ch != nil {
		ch <- true
	}
}

// gha2db - main work horse
func gha2db(args []string) {
	// Environment context parse
	var (
		ctx      lib.Ctx
		err      error
		hourFrom int
		hourTo   int
		dFrom    time.Time
		dTo      time.Time
	)
	ctx.Init()

	// Current date
	now := time.Now()
	startD, startH, endD, endH := args[0], args[1], args[2], args[3]

	// Parse from day & hour
	if strings.ToLower(startH) == lib.Now {
		hourFrom = now.Hour()
	} else {
		hourFrom, err = strconv.Atoi(startH)
		lib.FatalOnError(err)
	}

	if strings.ToLower(startD) == lib.Today {
		dFrom = lib.DayStart(now).Add(time.Duration(hourFrom) * time.Hour)
	} else {
		dFrom, err = time.Parse(
			time.RFC3339,
			fmt.Sprintf("%sT%02d:00:00+00:00", startD, hourFrom),
		)
		lib.FatalOnError(err)
	}

	// Parse to day & hour
	if strings.ToLower(endH) == lib.Now {
		hourTo = now.Hour()
	} else {
		hourTo, err = strconv.Atoi(endH)
		lib.FatalOnError(err)
	}

	if strings.ToLower(endD) == lib.Today {
		dTo = lib.DayStart(now).Add(time.Duration(hourTo) * time.Hour)
	} else {
		dTo, err = time.Parse(
			time.RFC3339,
			fmt.Sprintf("%sT%02d:00:00+00:00", endD, hourTo),
		)
		lib.FatalOnError(err)
	}

	// Strip function to be used by MapString
	stripFunc := func(x string) string { return strings.TrimSpace(x) }

	// Stripping whitespace from org and repo params
	var org map[string]struct{}
	if len(args) >= 5 {
		org = lib.StringsMapToSet(
			stripFunc,
			strings.Split(args[4], ","),
		)
	}

	var repo map[string]struct{}
	if len(args) >= 6 {
		repo = lib.StringsMapToSet(
			stripFunc,
			strings.Split(args[5], ","),
		)
	}

	// Get number of CPUs available
	thrN := lib.GetThreadsNum(&ctx)
	lib.Printf(
		"gha2db.go: Running (%v CPUs): %v - %v %v %v\n",
		thrN, dFrom, dTo,
		strings.Join(lib.StringsSetKeys(org), "+"),
		strings.Join(lib.StringsSetKeys(repo), "+"),
	)

	// GDPR data hiding
	shaMap := lib.GetHidden(lib.HideCfgFile)

	dt := dFrom
	if thrN > 1 {
		ch := make(chan bool)
		nThreads := 0
		for dt.Before(dTo) || dt.Equal(dTo) {
			go getGHAJSON(ch, &ctx, dt, org, repo, shaMap)
			dt = dt.Add(time.Hour)
			nThreads++
			if nThreads == thrN {
				<-ch
				nThreads--
			}
		}
		lib.Printf("Final threads join\n")
		for nThreads > 0 {
			<-ch
			nThreads--
		}
	} else {
		lib.Printf("Using single threaded version\n")
		for dt.Before(dTo) || dt.Equal(dTo) {
			getGHAJSON(nil, &ctx, dt, org, repo, shaMap)
			dt = dt.Add(time.Hour)
		}
	}
	// Finished
	lib.Printf("All done.\n")
}

func main() {
	dtStart := time.Now()
	// Required args
	if len(os.Args) < 5 {
		lib.Printf(
			"Arguments required: date_from_YYYY-MM-DD hour_from_HH date_to_YYYY-MM-DD hour_to_HH " +
				"['org1,org2,...,orgN' ['repo1,repo2,...,repoN']]\n",
		)
		os.Exit(1)
	}
	gha2db(os.Args[1:])
	dtEnd := time.Now()
	lib.Printf("Time: %v\n", dtEnd.Sub(dtStart))
}
