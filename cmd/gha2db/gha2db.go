package main

import (
	"bytes"
	"compress/gzip"
	"database/sql"
	"encoding/json"
	"fmt"
	"hash/fnv"
	"io/ioutil"
	lib "k8s.io/test-infra/gha2db"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

// Ctx - environment context packed in structure
type Ctx struct {
	Debug   int
	jsonOut bool
	dbOut   bool
}

func hashStrings(strs []string) int {
	h := fnv.New64a()
	s := ""
	for _, str := range strs {
		s += str
	}
	h.Write([]byte(s))
	res := int(h.Sum64())
	if res > 0 {
		res *= -1
	}
	return res
}

// Inserts single GHA Actor
func ghaActor(con *sql.Tx, actor lib.Actor) {
	// gha_actors
	// {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592,
	// "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
	// {"id"=>8, "login"=>34, "display_login"=>34, "gravatar_id"=>0, "url"=>63, "avatar_url"=>49}
	lib.ExecSQLTxWithErr(
		con,
		lib.InsertIgnore("into gha_actors(id, login) "+lib.NValues(2)),
		lib.AnyArray{actor.ID, actor.Login}...,
	)
}

// Inserts single GHA Milestone
func ghaMilestone(con *sql.Tx, eid string, milestone lib.Milestone) {
	// creator
	if milestone.Creator != nil {
		ghaActor(con, *milestone.Creator)
	}

	// gha_milestones
	lib.ExecSQLTxWithErr(
		con,
		"insert into gha_milestones("+
			"id, event_id, closed_at, closed_issues, created_at, creator_id, "+
			"description, due_on, number, open_issues, state, title, updated_at"+
			") "+lib.NValues(13),
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
		}...,
	)
}

func lookupLabel(con *sql.Tx, name string, color string) int {
	rows := lib.QuerySQLTxWithErr(
		con,
		fmt.Sprintf(
			"select id from gha_labels where name=%s and color=%s",
			lib.NValue(1),
			lib.NValue(2),
		),
		name,
		color,
	)
	defer rows.Close()
	lid := 0
	for rows.Next() {
		lib.FatalOnError(rows.Scan(&lid))
	}
	lib.FatalOnError(rows.Err())
	if lid == 0 {
		lid = hashStrings([]string{name, color})
	}
	return lid
}

func writeToDB(ctx Ctx, db *sql.DB, ev lib.Event) int {
	// gha_events
	// {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592,
	// "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592,
	// "org:Hash"=>19451}
	// {"id"=>10, "type"=>29, "actor"=>278, "repo"=>290, "payload"=>216017, "public"=>4,
	// "created_at"=>20, "org"=>230}
	// Fields actor_login, repo_name are copied from (gha_actors and gha_repos) to save
	// joins on complex queries (MySQL has no hash joins and is very slow on big tables joins)
	eventID := ev.ID
	rows := lib.QuerySQLWithErr(db, fmt.Sprintf("select 1 from gha_events where id=%s", lib.NValue(1)), eventID)
	defer rows.Close()
	exists := 0
	for rows.Next() {
		exists = 1
	}
	if exists == 1 {
		return 0
	}

	// Start transaction for entire event
	con, err := db.Begin()
	lib.FatalOnError(err)
	lib.ExecSQLTxWithErr(
		con,
		"insert into gha_events("+
			"id, type, actor_id, repo_id, public, created_at, "+
			"actor_login, repo_name, org_id) "+lib.NValues(9),
		lib.AnyArray{
			eventID,
			ev.Type,
			ev.Actor.ID,
			ev.Repo.ID,
			ev.Public,
			ev.CreatedAt,
			ev.Actor.Login,
			ev.Repo.Name,
			lib.OrgIDOrNil(ev.Org),
		}...,
	)

	// gha_actors
	ghaActor(con, ev.Actor)

	// gha_repos
	// {"id:Fixnum"=>48592, "name:String"=>48592, "url:String"=>48592}
	// {"id"=>8, "name"=>111, "url"=>140}
	repo := ev.Repo
	lib.ExecSQLTxWithErr(
		con,
		lib.InsertIgnore("into gha_repos(id, name) "+lib.NValues(2)),
		lib.AnyArray{repo.ID, repo.Name}...,
	)

	// gha_orgs
	// {"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494,
	// "url:String"=>18494, "avatar_url:String"=>18494}
	// {"id"=>8, "login"=>38, "gravatar_id"=>0, "url"=>66, "avatar_url"=>49}
	org := ev.Org
	if org != nil {
		lib.ExecSQLTxWithErr(
			con,
			lib.InsertIgnore("into gha_orgs(id, login) "+lib.NValues(2)),
			lib.AnyArray{org.ID, org.Login}...,
		)
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
	pl := ev.Payload
	lib.ExecSQLTxWithErr(
		con,
		"insert into gha_payloads("+
			"event_id, push_id, size, ref, head, befor, action, "+
			"issue_id, comment_id, ref_type, master_branch, "+
			"description, number, forkee_id, release_id, member_id"+
			") "+lib.NValues(16),
		lib.AnyArray{
			eventID,
			lib.IntOrNil(pl.PushID),
			lib.IntOrNil(pl.Size),
			lib.TruncStringOrNil(pl.Ref, 200),
			lib.StringOrNil(pl.Head),
			lib.StringOrNil(pl.Before),
			lib.StringOrNil(pl.Action),
			lib.IssueIDOrNil(pl.Issue),
			lib.CommentIDOrNil(pl.Comment),
			lib.StringOrNil(pl.RefType),
			lib.TruncStringOrNil(pl.MasterBranch, 200),
			lib.TruncStringOrNil(pl.Description, 0xffff),
			lib.IntOrNil(pl.Number),
			lib.ForkeeIDOrNil(pl.Forkee),
			lib.ReleaseIDOrNil(pl.Release),
			lib.ActorIDOrNil(pl.Member),
		}...,
	)

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
			"insert into gha_commits("+
				"sha, event_id, author_name, message, is_distinct) "+lib.NValues(5),
			lib.AnyArray{
				sha,
				eventID,
				lib.TruncToBytes(commit.Author.Name, 160),
				lib.TruncToBytes(commit.Message, 0xffff), // FIXME: in gha2db.rb it was allowing null, while DB structure doesn not permit this
				commit.Distinct,
			}...,
		)
	}

	// gha_pages
	// {"page_name:String"=>370, "title:String"=>370, "summary:NilClass"=>370,
	// "action:String"=>370, "sha:String"=>370, "html_url:String"=>370}
	// {"page_name"=>65, "title"=>65, "summary"=>0, "action"=>7, "sha"=>40, "html_url"=>130}
	// 370
	pages := []lib.Page{}
	if pl.Pages != nil {
		pages = *pl.Pages
	}
	for _, page := range pages {
		sha := page.SHA
		lib.ExecSQLTxWithErr(
			con,
			lib.InsertIgnore("into gha_pages(sha, event_id, action, title) "+lib.NValues(4)),
			lib.AnyArray{
				sha,
				eventID,
				page.Action,
				lib.TruncToBytes(page.Title, 300),
			}...,
		)
	}

	// member
	if pl.Member != nil {
		ghaActor(con, *pl.Member)
	}

	// gha_comments
	// Table details and analysis in `analysis/analysis.txt` and `analysis/comment_*.json`
	if pl.Comment != nil {
		comment := *pl.Comment
		// user
		ghaActor(con, comment.User)

		// comment
		cid := comment.ID
		lib.ExecSQLTxWithErr(
			con,
			lib.InsertIgnore(
				"into gha_comments("+
					"id, event_id, body, created_at, updated_at, type, user_id, "+
					"commit_id, original_commit_id, diff_hunk, position, "+
					"original_position, path, pull_request_review_id, line"+
					") "+lib.NValues(15),
			),
			lib.AnyArray{
				cid,
				eventID,
				lib.TruncToBytes(comment.Body, 0xffff), // FIXME: gha2db.rb was using conditional nil here
				comment.CreatedAt,
				comment.UpdatedAt,
				ev.Type,
				comment.User.ID,
				lib.StringOrNil(comment.CommitID),
				lib.StringOrNil(comment.OriginalCommitID),
				lib.StringOrNil(comment.DiffHunk),
				lib.IntOrNil(comment.Position),
				lib.IntOrNil(comment.OriginalPosition),
				lib.StringOrNil(comment.Path),
				lib.IntOrNil(comment.PullRequestReviewID),
				lib.IntOrNil(comment.Line),
			}...,
		)
	}

	// gha_issues
	// Table details and analysis in `analysis/analysis.txt` and `analysis/issue_*.json`
	if pl.Issue != nil {
		issue := *pl.Issue

		// user, assignee
		ghaActor(con, issue.User)
		if issue.Assignee != nil {
			ghaActor(con, *issue.Assignee)
		}

		// issue
		iid := issue.ID
		isPR := false
		if issue.PullRequest != nil {
			isPR = true
		}
		lib.ExecSQLTxWithErr(
			con,
			"insert into gha_issues("+
				"id, event_id, assignee_id, body, closed_at, comments, created_at, "+
				"locked, milestone_id, number, state, title, updated_at, user_id, "+
				"is_pull_request) "+lib.NValues(15),
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
				isPR,
			}...,
		)

		// milestone
		if issue.Milestone != nil {
			ghaMilestone(con, eventID, *issue.Milestone)
		}

		pAid := lib.ActorIDOrNil(issue.Assignee)
		for _, assignee := range issue.Assignees {
			aid := assignee.ID
			if aid == pAid {
				continue
			}

			// assignee
			ghaActor(con, assignee)

			// issue-assignee connection
			lib.ExecSQLTxWithErr(
				con,
				"insert into gha_issues_assignees(issue_id, event_id, assignee_id) "+lib.NValues(3),
				lib.AnyArray{iid, eventID, assignee.ID}...,
			)
		}

		// labels
		for _, label := range issue.Labels {
			lid := lib.IntOrNil(label.ID)
			if lid == nil {
				lid = lookupLabel(con, lib.TruncToBytes(label.Name, 160), label.Color)
			}

			// label
			lib.ExecSQLTxWithErr(
				con,
				lib.InsertIgnore("into gha_labels(id, name, color, is_default) "+lib.NValues(4)),
				lib.AnyArray{lid, lib.TruncToBytes(label.Name, 160), label.Color, lib.BoolOrNil(label.Default)}...,
			)

			// issue-label connection
			lib.ExecSQLTxWithErr(
				con,
				lib.InsertIgnore("into gha_issues_labels(issue_id, event_id, label_id) "+lib.NValues(3)),
				lib.AnyArray{iid, eventID, lid}...,
			)
		}
	}
	/*
	  # gha_forkees
	  gha_forkee(con, sid, event_id, pl['forkee']) if pl['forkee']

	  # gha_releases
	  # Table details and analysis in `analysis/analysis.txt` and `analysis/release_*.json`
	  release = pl['release']
	  if release
	    # author
	    gha_actor(con, sid, release['author'])

	    # release
	    rid = release['id']
	    exec_stmt(
	      con,
	      sid,
	      'insert into gha_releases('\
	      'id, event_id, tag_name, target_commitish, name, draft, '\
	      'author_id, prerelease, created_at, published_at, body'\
	      ') ' + n_values(11),
	      [
	        rid,
	        event_id,
	        trunc(release['tag_name'], 200),
	        trunc(release['target_commitish'], 200),
	        release['name'] ? trunc(release['name'], 200) : nil,
	        release['draft'],
	        release['author']['id'],
	        release['prerelease'],
	        parse_timestamp(release['created_at']),
	        parse_timestamp(release['published_at']),
	        release['body'] ? trunc(release['body'], 0xffff) : nil
	      ]
	    )

	    # assets
	    assets = release['assets']
	    assets.each do |asset|
	      # uploader
	      gha_actor(con, sid, asset['uploader'])

	      # asset
	      aid = asset['id']
	      exec_stmt(
	        con,
	        sid,
	        'insert into gha_assets('\
	        'id, event_id, name, label, uploader_id, content_type, '\
	        'state, size, download_count, created_at, updated_at'\
	        ') ' + n_values(11),
	        [
	          aid,
	          event_id,
	          trunc(asset['name'], 200),
	          asset['label'] ? trunc(asset['label'], 120) : nil,
	          asset['uploader']['id'],
	          asset['content_type'],
	          asset['state'],
	          asset['size'],
	          asset['download_count'],
	          parse_timestamp(asset['created_at']),
	          parse_timestamp(asset['updated_at'])
	        ]
	      )

	      # release-asset connection
	      exec_stmt(
	        con,
	        sid,
	        'insert into gha_releases_assets(release_id, event_id, asset_id) ' + n_values(3),
	        [rid, event_id, aid]
	      )
	    end
	  end

	  # gha_pull_requests
	  # Table details and analysis in `analysis/analysis.txt` and `analysis/pull_request_*.json`
	  pr = pl['pull_request']
	  if pr
	    # gha_pull_requests

	    # user
	    gha_actor(con, sid, pr['user'])

	    base_sha = pr['base']['sha']
	    head_sha = pr['head']['sha']
	    base_repo_id = pr['base']['repo'] && pr['base']['repo']['id']

	    # base
	    gha_branch(con, sid, event_id, pr['base'])

	    # head (if different, and skip its repo if defined and the same as base repo)
	    gha_branch(con, sid, event_id, pr['head'], base_repo_id) unless base_sha == head_sha

	    # merged_by
	    gha_actor(con, sid, pr['merged_by']) if pr['merged_by']

	    # assignee
	    gha_actor(con, sid, pr['assignee']) if pr['assignee']

	    # milestone
	    gha_milestone(con, sid, event_id, pr['milestone']) if pr['milestone']

	    # pull_request
	    prid = pr['id']
	    exec_stmt(
	      con,
	      sid,
	      'insert into gha_pull_requests('\
	      'id, event_id, user_id, base_sha, head_sha, merged_by_id, assignee_id, milestone_id, '\
	      'number, state, locked, title, body, created_at, updated_at, closed_at, merged_at, '\
	      'merge_commit_sha, merged, mergeable, rebaseable, mergeable_state, comments, '\
	      'review_comments, maintainer_can_modify, commits, additions, deletions, changed_files'\
	      ') ' + n_values(29),
	      [
	        prid,
	        event_id,
	        pr['user']['id'],
	        base_sha,
	        head_sha,
	        pr['merged_by'] ? pr['merged_by']['id'] : nil,
	        pr['assignee'] ? pr['assignee']['id'] : nil,
	        pr['milestone'] ? pr['milestone']['id'] : nil,
	        pr['number'],
	        pr['state'],
	        pr['locked'],
	        pr['title'],
	        pr['body'] ? trunc(pr['body'], 0xffff) : nil,
	        parse_timestamp(pr['created_at']),
	        parse_timestamp(pr['updated_at']),
	        pr['closed_at'] ? parse_timestamp(pr['closed_at']) : nil,
	        pr['merged_at'] ? parse_timestamp(pr['merged_at']) : nil,
	        pr['merge_commit_sha'],
	        pr['merged'],
	        pr['mergeable'],
	        pr['rebaseable'],
	        pr['mergeable_state'],
	        pr['comments'],
	        pr['review_comments'],
	        pr['maintainer_can_modify'],
	        pr['commits'],
	        pr['additions'],
	        pr['deletions'],
	        pr['changed_files']
	      ]
	    )

	    # Arrays: actors: assignees, requested_reviewers
	    # assignees
	    assignees = pr['assignees'] || []
	    p_aid = pr['assignee'] ? pr['assignee']['id'] : nil
	    assignees.each do |assignee|
	      aid = assignee['id']
	      next if aid == p_aid

	      # assignee
	      gha_actor(con, sid, assignee)

	      # pull_request-assignee connection
	      exec_stmt(
	        con,
	        sid,
	        'insert into gha_pull_requests_assignees('\
	        'pull_request_id, event_id, assignee_id) ' + n_values(3),
	        [prid, event_id, aid]
	      )
	    end

	    # requested_reviewers
	    reviewers = pr['requested_reviewers'] || []
	    reviewers.each do |reviewer|
	      # reviewer
	      gha_actor(con, sid, reviewer)

	      # pull_request-requested_reviewer connection
	      exec_stmt(
	        con,
	        sid,
	        'insert into gha_pull_requests_requested_reviewers('\
	        'pull_request_id, event_id, requested_reviewer_id) ' + n_values(3),
	        [prid, event_id, reviewer['id']]
	      )
	    end
	  end
	*/
	lib.FatalOnError(con.Commit())
	return 1
}

// repoHit - are we interested in this org/repo ?
func repoHit(fullName string, forg, frepo map[string]bool) bool {
	if fullName == "" {
		return false
	}
	res := strings.Split(fullName, "/")
	org, repo := res[0], res[1]
	if len(forg) > 0 {
		if _, ok := forg[org]; !ok {
			return false
		}
	}
	if len(frepo) > 0 {
		if _, ok := frepo[repo]; !ok {
			return false
		}
	}
	return true
}

// parseJSON - parse signle GHA JSON event
func parseJSON(ctx Ctx, con *sql.DB, jsonStr []byte, dt time.Time, forg, frepo map[string]bool) (f int, e int) {
	var h lib.Event
	err := json.Unmarshal(jsonStr, &h)
	if err != nil {
		fmt.Printf("'%v'\n", string(jsonStr))
	}
	lib.FatalOnError(err)
	fullName := h.Repo.Name
	if repoHit(fullName, forg, frepo) {
		eid := h.ID
		if ctx.jsonOut {
			// We want to Unmarshal/Marshall ALL JSON data, regardless of what is defined in lib.Event
			pretty := lib.PrettyPrintJSON(jsonStr)
			ofn := fmt.Sprintf("jsons/%v_%v.json", dt.Unix(), eid)
			lib.FatalOnError(ioutil.WriteFile(ofn, pretty, 0644))
		}
		if ctx.dbOut {
			// FIXME: not needed
			// fmt.Printf("JSON:\n%v\n", string(lib.PrettyPrintJSON(jsonStr)))
			e = writeToDB(ctx, con, h)
		}
		if ctx.Debug >= 1 {
			fmt.Printf("Processed: '%v' event: %v\n", dt, eid)
		}
		f = 1
	}
	return
}

// getGHAJSON - This is a work for single go routine - 1 hour of GHA data
// Usually such JSON conatin about 15000 - 60000 singe GHA events
// Boolean channel `ch` is used to synchronize go routines
func getGHAJSON(ch chan bool, ctx Ctx, dt time.Time, forg map[string]bool, frepo map[string]bool) {
	fmt.Printf("Working on %v\n", dt)

	// Connect to Postgres DB
	con, err := lib.Conn()
	lib.FatalOnError(err)
	defer con.Close()

	fn := fmt.Sprintf(
		"http://data.githubarchive.org/%04d-%02d-%02d-%d.json.gz",
		dt.Year(), dt.Month(), dt.Day(), dt.Hour(),
	)

	// Get gzipped JSON array via HTTP
	response, err := http.Get(fn)
	lib.FatalOnError(err)
	defer response.Body.Close()

	// Decompress Gzipped response
	reader, err := gzip.NewReader(response.Body)
	lib.FatalOnError(err)
	fmt.Printf("Opened %s\n", fn)
	defer reader.Close()
	jsonsBytes, err := ioutil.ReadAll(reader)
	lib.FatalOnError(err)
	fmt.Printf("Decompressed %s\n", fn)

	// Split JSON array into separate JSONs
	jsonsArray := bytes.Split(jsonsBytes, []byte("\n"))
	fmt.Printf("Splitted %s, %d JSONs\n", fn, len(jsonsArray))

	// Process JSONs one by one
	n, f, e := 0, 0, 0
	for _, json := range jsonsArray {
		if len(json) < 1 {
			continue
		}
		fi, ei := parseJSON(ctx, con, json, dt, forg, frepo)
		n++
		f += fi
		e += ei
	}
	fmt.Printf(
		"Parsed: %s: %d JSONs, found %d matching, events %d\n",
		fn, n, f, e,
	)
	if ch != nil {
		ch <- true
	}
}

// gha2db - main work horse
func gha2db(args []string) {
	// Environment context parse
	var ctx Ctx
	ctx.jsonOut = os.Getenv("GHA2DB_JSON") != ""
	ctx.dbOut = os.Getenv("GHA2DB_NODB") == ""
	if os.Getenv("GHA2DB_DEBUG") == "" {
		ctx.Debug = 0
	} else {
		debugLevel, err := strconv.Atoi(os.Getenv("GHA2DB_DEBUG"))
		lib.FatalOnError(err)
		ctx.Debug = debugLevel
	}

	hourFrom, err := strconv.Atoi(args[1])
	lib.FatalOnError(err)
	dFrom, err := time.Parse(
		time.RFC3339,
		fmt.Sprintf("%sT%02d:00:00+00:00", args[0], hourFrom),
	)
	lib.FatalOnError(err)

	hourTo, err := strconv.Atoi(args[3])
	lib.FatalOnError(err)
	dTo, err := time.Parse(
		time.RFC3339,
		fmt.Sprintf("%sT%02d:00:00+00:00", args[2], hourTo),
	)
	lib.FatalOnError(err)

	// Strip function to be used by MapString
	stripFunc := func(x string) string { return strings.TrimSpace(x) }

	// Stripping whitespace from org and repo params
	var org map[string]bool
	if len(args) >= 5 {
		org = lib.StringsMapToSet(
			stripFunc,
			strings.Split(args[4], ","),
		)
	}

	var repo map[string]bool
	if len(args) >= 6 {
		repo = lib.StringsMapToSet(
			stripFunc,
			strings.Split(args[5], ","),
		)
	}

	// Get number of CPUs available
	thrN := lib.GetThreadsNum()
	fmt.Printf(
		"Running (%v CPUs): %v - %v %v %v\n",
		thrN, dFrom, dTo,
		strings.Join(lib.StringsSetKeys(org), "+"),
		strings.Join(lib.StringsSetKeys(repo), "+"),
	)

	dt := dFrom
	if thrN > 1 {
		chanPool := []chan bool{}
		for dt.Before(dTo) || dt.Equal(dTo) {
			ch := make(chan bool)
			chanPool = append(chanPool, ch)
			go getGHAJSON(ch, ctx, dt, org, repo)
			dt = dt.Add(time.Hour)
			if len(chanPool) == thrN {
				ch = chanPool[0]
				<-ch
				chanPool = chanPool[1:]
			}
		}
		fmt.Printf("Final threads join\n")
		for _, ch := range chanPool {
			<-ch
		}
	} else {
		fmt.Printf("Using single threaded version\n")
		for dt.Before(dTo) || dt.Equal(dTo) {
			getGHAJSON(nil, ctx, dt, org, repo)
			dt = dt.Add(time.Hour)
		}
	}

	fmt.Printf("All done.\n")
}

func main() {
	// Required args
	if len(os.Args) < 5 {
		fmt.Printf(
			"Arguments required: date_from_YYYY-MM-DD hour_from_HH date_to_YYYY-MM-DD hour_to_HH " +
				"['org1,org2,...,orgN' ['repo1,repo2,...,repoN']]\n",
		)
		os.Exit(1)
	}
	gha2db(os.Args[1:])
}
