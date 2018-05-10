package devstats

import (
	"time"
)

// Structure creates full database structure, indexes, views/summary tables etc
func Structure(ctx *Ctx) {
	// Connect to Postgres DB
	c := PgConn(ctx)
	defer func() { FatalOnError(c.Close()) }()

	// gha_events
	// {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592,
	// "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592, "org:Hash"=>19451}
	// {"id"=>10, "type"=>29, "actor"=>278, "repo"=>290, "payload"=>216017, "public"=>4,
	// "created_at"=>20, "org"=>230}
	// const
	// dup columns: dup_actor_login, dup_repo_name
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_events")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_events("+
					"id bigint not null primary key, "+
					"type varchar(40) not null, "+
					"actor_id bigint not null, "+
					"repo_id bigint not null, "+
					"public boolean not null, "+
					"created_at {{ts}} not null, "+
					"org_id bigint, "+
					"forkee_id bigint, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_name varchar(160) not null"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index events_type_idx on gha_events(type)")
		ExecSQLWithErr(c, ctx, "create index events_actor_id_idx on gha_events(actor_id)")
		ExecSQLWithErr(c, ctx, "create index events_repo_id_idx on gha_events(repo_id)")
		ExecSQLWithErr(c, ctx, "create index events_org_id_idx on gha_events(org_id)")
		ExecSQLWithErr(c, ctx, "create index events_forkee_id_idx on gha_events(forkee_id)")
		ExecSQLWithErr(c, ctx, "create index events_created_at_idx on gha_events(created_at)")
		ExecSQLWithErr(c, ctx, "create index events_dup_actor_login_idx on gha_events(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index events_dup_repo_name_idx on gha_events(dup_repo_name)")
	}

	// gha_actors
	// {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592,
	// "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
	// {"id"=>8, "login"=>34, "display_login"=>34, "gravatar_id"=>0, "url"=>63,
	// "avatar_url"=>49}
	// const
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_actors")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_actors("+
					"id bigint not null primary key, "+
					"login varchar(120) not null, "+
					"name varchar(120)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index actors_login_idx on gha_actors(login)")
		ExecSQLWithErr(c, ctx, "create index actors_name_idx on gha_actors(name)")
	}

	// gha_actors_emails: this is filled by `import_affs` tool, that uses cncf/gitdm:github_users.json
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_actors_emails")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_actors_emails("+
					"actor_id bigint not null, "+
					"email varchar(120) not null, "+
					"primary key(actor_id, email)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index actors_emails_actor_id_idx on gha_actors_emails(actor_id)")
		ExecSQLWithErr(c, ctx, "create index actors_emails_email_idx on gha_actors_emails(email)")
	}

	// gha_companies: this is filled by `import_affs` tool, that uses cncf/gitdm:github_users.json
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_companies")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_companies("+
					"name varchar(160) not null, "+
					"primary key(name)"+
					")",
			),
		)
	}

	// gha_actors_affiliations: this is filled by `import_affs` tool, that uses cncf/gitdm:github_users.json
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_actors_affiliations")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_actors_affiliations("+
					"actor_id bigint not null, "+
					"company_name varchar(160) not null, "+
					"dt_from {{ts}} not null, "+
					"dt_to {{ts}} not null, "+
					"primary key(actor_id, company_name, dt_from, dt_to)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index actors_affiliations_actor_id_idx on gha_actors_affiliations(actor_id)")
		ExecSQLWithErr(c, ctx, "create index actors_affiliations_company_name_idx on gha_actors_affiliations(company_name)")
		ExecSQLWithErr(c, ctx, "create index actors_affiliations_dt_from_idx on gha_actors_affiliations(dt_from)")
		ExecSQLWithErr(c, ctx, "create index actors_affiliations_dt_to_idx on gha_actors_affiliations(dt_to)")
	}

	// gha_repos
	// {"id:Fixnum"=>48592, "name:String"=>48592, "url:String"=>48592}
	// {"id"=>8, "name"=>111, "url"=>140}
	// const
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_repos")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_repos("+
					"id bigint not null, "+
					"name varchar(160) not null, "+
					"org_id bigint, "+
					"org_login varchar(100), "+
					"repo_group varchar(80), "+
					"alias varchar(160), "+
					"primary key(id, name))",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index repos_name_idx on gha_repos(name)")
		ExecSQLWithErr(c, ctx, "create index repos_org_id_idx on gha_repos(org_id)")
		ExecSQLWithErr(c, ctx, "create index repos_org_login_idx on gha_repos(org_login)")
		ExecSQLWithErr(c, ctx, "create index repos_repo_group_idx on gha_repos(repo_group)")
		ExecSQLWithErr(c, ctx, "create index repos_alias_idx on gha_repos(alias)")
	}

	// gha_orgs
	// {"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494,
	// "url:String"=>18494, "avatar_url:String"=>18494}
	// {"id"=>8, "login"=>38, "gravatar_id"=>0, "url"=>66, "avatar_url"=>49}
	// const
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_orgs")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_orgs("+
					"id bigint not null primary key, "+
					"login varchar(100) not null"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index orgs_login_idx on gha_orgs(login)")
	}

	// gha_payloads
	// {"push_id:Fixnum"=>24636, "size:Fixnum"=>24636, "distinct_size:Fixnum"=>24636,
	// "ref:String"=>30522, "head:String"=>24636, "before:String"=>24636, "commits:Array"=>24636,
	// "action:String"=>14317, "issue:Hash"=>6446, "comment:Hash"=>6055, "ref_type:String"=>8010,
	// "master_branch:String"=>6724, "description:String"=>3701, "pusher_type:String"=>8010,
	// "pull_request:Hash"=>4475, "ref:NilClass"=>2124, "description:NilClass"=>3023,
	// "number:Fixnum"=>2992, "forkee:Hash"=>1211, "pages:Array"=>370,
	// "release:Hash"=>156, "member:Hash"=>219}
	// {"push_id"=>10, "size"=>4, "distinct_size"=>4, "ref"=>110, "head"=>40, "before"=>40,
	// "commits"=>33215, "action"=>9, "issue"=>87776, "comment"=>177917, "ref_type"=>10,
	// "master_branch"=>34, "description"=>3222, "pusher_type"=>4, "pull_request"=>70565,
	// "number"=>5, "forkee"=>6880, "pages"=>855, "release"=>31206, "member"=>1040}
	// 48746
	// const
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_payloads")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_payloads("+
					"event_id bigint not null primary key, "+
					"push_id bigint, "+
					"size int, "+
					"ref varchar(200), "+
					"head varchar(40), "+
					"befor varchar(40), "+
					"action varchar(20), "+
					"issue_id bigint, "+
					"pull_request_id bigint, "+
					"comment_id bigint, "+
					"ref_type varchar(20), "+
					"master_branch varchar(200), "+
					"description text, "+
					"number int, "+
					"forkee_id bigint, "+
					"release_id bigint, "+
					"member_id bigint, "+
					"commit varchar(40), "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index payloads_action_idx on gha_payloads(action)")
		ExecSQLWithErr(c, ctx, "create index payloads_head_idx on gha_payloads(head)")
		ExecSQLWithErr(c, ctx, "create index payloads_issue_id_idx on gha_payloads(issue_id)")
		ExecSQLWithErr(c, ctx, "create index payloads_pull_request_id_idx on gha_payloads(issue_id)")
		ExecSQLWithErr(c, ctx, "create index payloads_comment_id_idx on gha_payloads(comment_id)")
		ExecSQLWithErr(c, ctx, "create index payloads_ref_type_idx on gha_payloads(ref_type)")
		ExecSQLWithErr(c, ctx, "create index payloads_forkee_id_idx on gha_payloads(forkee_id)")
		ExecSQLWithErr(c, ctx, "create index payloads_release_id_idx on gha_payloads(release_id)")
		ExecSQLWithErr(c, ctx, "create index payloads_member_id_idx on gha_payloads(member_id)")
		ExecSQLWithErr(c, ctx, "create index payloads_commit_idx on gha_payloads(commit)")
		ExecSQLWithErr(c, ctx, "create index payloads_dup_actor_id_idx on gha_payloads(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index payloads_dup_actor_login_idx on gha_payloads(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index payloads_dup_repo_id_idx on gha_payloads(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index payloads_dup_repo_name_idx on gha_payloads(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index payloads_dup_type_idx on gha_payloads(dup_type)")
		ExecSQLWithErr(c, ctx, "create index payloads_dup_created_at_idx on gha_payloads(dup_created_at)")
	}

	// gha_commits
	// {"sha:String"=>23265, "author:Hash"=>23265, "message:String"=>23265,
	// "distinct:TrueClass"=>21789, "url:String"=>23265, "distinct:FalseClass"=>1476}
	// {"sha"=>40, "author"=>177, "message"=>19005, "distinct"=>5, "url"=>191}
	// author: {"name:String"=>23265, "email:String"=>23265} (only git username/email)
	// author: {"name"=>96, "email"=>95}
	// 23265
	// variable (per event)
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_commits")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_commits("+
					"sha varchar(40) not null, "+
					"event_id bigint not null, "+
					"author_name varchar(160) not null, "+
					"message text not null, "+
					"is_distinct boolean not null, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"primary key(sha, event_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index commits_event_id_idx on gha_commits(event_id)")
		ExecSQLWithErr(c, ctx, "create index commits_dup_actor_id_idx on gha_commits(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index commits_dup_actor_login_idx on gha_commits(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index commits_dup_repo_id_idx on gha_commits(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index commits_dup_repo_name_idx on gha_commits(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index commits_dup_type_idx on gha_commits(dup_type)")
		ExecSQLWithErr(c, ctx, "create index commits_dup_created_at_idx on gha_commits(dup_created_at)")
	}

	// gha_pages
	// {"page_name:String"=>370, "title:String"=>370, "summary:NilClass"=>370,
	// "action:String"=>370, "sha:String"=>370, "html_url:String"=>370}
	// {"page_name"=>65, "title"=>65, "summary"=>0, "action"=>7, "sha"=>40, "html_url"=>130}
	// 370
	// variable
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_pages")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_pages("+
					"sha varchar(40) not null, "+
					"event_id bigint not null, "+
					"action varchar(20) not null, "+
					"title varchar(300) not null, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"primary key(sha, event_id, action, title)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index pages_event_id_idx on gha_pages(event_id)")
		ExecSQLWithErr(c, ctx, "create index pages_action_idx on gha_pages(action)")
		ExecSQLWithErr(c, ctx, "create index pages_dup_actor_id_idx on gha_pages(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index pages_dup_actor_login_idx on gha_pages(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index pages_dup_repo_id_idx on gha_pages(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index pages_dup_repo_name_idx on gha_pages(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index pages_dup_type_idx on gha_pages(dup_type)")
		ExecSQLWithErr(c, ctx, "create index pages_dup_created_at_idx on gha_pages(dup_created_at)")
	}

	// gha_comments
	// Table details and analysis in `analysis/analysis.txt` and `analysis/comment_*.json`
	// Keys: user_id, commit_id, original_commit_id, pull_request_review_id
	// variable
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_comments")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_comments("+
					"id bigint not null, "+
					"event_id bigint not null, "+
					"body text not null, "+
					"created_at {{ts}} not null, "+
					"updated_at {{ts}} not null, "+
					"user_id bigint not null, "+
					"commit_id varchar(40), "+
					"original_commit_id varchar(40), "+
					"diff_hunk text, "+
					"position int, "+
					"original_position int, "+
					"path text, "+
					"pull_request_review_id bigint, "+
					"line int, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"dup_user_login varchar(120) not null, "+
					"primary key(id, event_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index comments_event_id_idx on gha_comments(event_id)")
		ExecSQLWithErr(c, ctx, "create index comments_created_at_idx on gha_comments(created_at)")
		ExecSQLWithErr(c, ctx, "create index comments_updated_at_idx on gha_comments(updated_at)")
		ExecSQLWithErr(c, ctx, "create index comments_user_id_idx on gha_comments(user_id)")
		ExecSQLWithErr(c, ctx, "create index comments_commit_id_idx on gha_comments(commit_id)")
		ExecSQLWithErr(
			c,
			ctx,
			"create index comments_pull_request_review_id_idx on gha_comments(pull_request_review_id)",
		)
		ExecSQLWithErr(c, ctx, "create index comments_dup_actor_id_idx on gha_comments(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index comments_dup_actor_login_idx on gha_comments(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index comments_dup_repo_id_idx on gha_comments(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index comments_dup_repo_name_idx on gha_comments(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index comments_dup_type_idx on gha_comments(dup_type)")
		ExecSQLWithErr(c, ctx, "create index comments_dup_created_at_idx on gha_comments(dup_created_at)")
		ExecSQLWithErr(c, ctx, "create index comments_dup_user_login_idx on gha_comments(dup_user_login)")
	}

	// gha_issues
	// Table details and analysis in `analysis/analysis.txt` and `analysis/issue_*.json`
	// Arrays: assignees, labels
	// Keys: assignee_id, milestone_id, user_id
	// variable
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_issues")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_issues("+
					"id bigint not null, "+
					"event_id bigint not null, "+
					"assignee_id bigint, "+
					"body text, "+
					"closed_at {{ts}}, "+
					"comments int not null, "+
					"created_at {{ts}} not null, "+
					"locked boolean not null, "+
					"milestone_id bigint, "+
					"number int not null, "+
					"state varchar(20) not null, "+
					"title text not null, "+
					"updated_at {{ts}} not null, "+
					"user_id bigint not null, "+
					"is_pull_request boolean not null, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"dupn_assignee_login varchar(120), "+
					"dup_user_login varchar(120) not null, "+
					"primary key(id, event_id)"+
					")",
			),
		)
		// variable
		ExecSQLWithErr(c, ctx, "drop table if exists gha_issues_assignees")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_issues_assignees("+
					"issue_id bigint not null, "+
					"event_id bigint not null, "+
					"assignee_id bigint not null, "+
					"primary key(issue_id, event_id, assignee_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index issues_event_id_idx on gha_issues(event_id)")
		ExecSQLWithErr(c, ctx, "create index issues_assignee_id_idx on gha_issues(assignee_id)")
		ExecSQLWithErr(c, ctx, "create index issues_created_at_idx on gha_issues(created_at)")
		ExecSQLWithErr(c, ctx, "create index issues_updated_at_idx on gha_issues(updated_at)")
		ExecSQLWithErr(c, ctx, "create index issues_closed_at_idx on gha_issues(closed_at)")
		ExecSQLWithErr(c, ctx, "create index issues_milestone_id_idx on gha_issues(milestone_id)")
		ExecSQLWithErr(c, ctx, "create index issues_state_idx on gha_issues(state)")
		ExecSQLWithErr(c, ctx, "create index issues_user_id_idx on gha_issues(user_id)")
		ExecSQLWithErr(c, ctx, "create index issues_is_pull_request_idx on gha_issues(is_pull_request)")
		ExecSQLWithErr(c, ctx, "create index issues_dup_actor_id_idx on gha_issues(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index issues_dup_actor_login_idx on gha_issues(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index issues_dup_repo_id_idx on gha_issues(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index issues_dup_repo_name_idx on gha_issues(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index issues_dup_type_idx on gha_issues(dup_type)")
		ExecSQLWithErr(c, ctx, "create index issues_dup_created_at_idx on gha_issues(dup_created_at)")
		ExecSQLWithErr(c, ctx, "create index issues_dup_user_login_idx on gha_issues(dup_user_login)")
		ExecSQLWithErr(c, ctx, "create index issues_dupn_assignee_login_idx on gha_issues(dupn_assignee_login)")
	}

	// gha_milestones
	// Table details and analysis in `analysis/analysis.txt` and `analysis/milestone_*.json`
	// Keys: creator_id
	// variable
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_milestones")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_milestones("+
					"id bigint not null, "+
					"event_id bigint not null, "+
					"closed_at {{ts}}, "+
					"closed_issues int not null, "+
					"created_at {{ts}} not null, "+
					"creator_id bigint, "+
					"description text, "+
					"due_on {{ts}}, "+
					"number int not null, "+
					"open_issues int not null, "+
					"state varchar(20) not null, "+
					"title varchar(200) not null, "+
					"updated_at {{ts}} not null, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"dupn_creator_login varchar(120), "+
					"primary key(id, event_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index milestones_event_id_idx on gha_milestones(event_id)")
		ExecSQLWithErr(c, ctx, "create index milestones_created_at_idx on gha_milestones(created_at)")
		ExecSQLWithErr(c, ctx, "create index milestones_updated_at_idx on gha_milestones(updated_at)")
		ExecSQLWithErr(c, ctx, "create index milestones_creator_id_idx on gha_milestones(creator_id)")
		ExecSQLWithErr(c, ctx, "create index milestones_state_idx on gha_milestones(state)")
		ExecSQLWithErr(c, ctx, "create index milestones_dup_actor_id_idx on gha_milestones(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index milestones_dup_actor_login_idx on gha_milestones(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index milestones_dup_repo_id_idx on gha_milestones(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index milestones_dup_repo_name_idx on gha_milestones(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index milestones_dup_type_idx on gha_milestones(dup_type)")
		ExecSQLWithErr(c, ctx, "create index milestones_dup_created_at_idx on gha_milestones(dup_created_at)")
		ExecSQLWithErr(c, ctx, "create index milestones_dupn_creator_login_idx on gha_milestones(dupn_creator_login)")
	}

	// gha_labels
	// Table details and analysis in `analysis/analysis.txt` and `analysis/label_*.json`
	// const
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_labels")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_labels("+
					"id bigint not null primary key, "+
					"name varchar(160) not null, "+
					"color varchar(8) not null, "+
					"is_default boolean"+
					")",
			),
		)
		// variable
		ExecSQLWithErr(c, ctx, "drop table if exists gha_issues_labels")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_issues_labels("+
					"issue_id bigint not null, "+
					"event_id bigint not null, "+
					"label_id bigint not null, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"dup_issue_number int not null, "+
					"dup_label_name varchar(160) not null, "+
					"primary key(issue_id, event_id, label_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index labels_name_idx on gha_labels(name)")

		// gha_issues_labels
		ExecSQLWithErr(c, ctx, "create index issues_labels_dup_actor_id_idx on gha_issues_labels(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index issues_labels_dup_actor_login_idx on gha_issues_labels(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index issues_labels_dup_repo_id_idx on gha_issues_labels(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index issues_labels_dup_repo_name_idx on gha_issues_labels(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index issues_labels_dup_type_idx on gha_issues_labels(dup_type)")
		ExecSQLWithErr(c, ctx, "create index issues_labels_dup_created_at_idx on gha_issues_labels(dup_created_at)")
		ExecSQLWithErr(c, ctx, "create index issues_labels_dup_issue_number_idx on gha_issues_labels(dup_issue_number)")
		ExecSQLWithErr(c, ctx, "create index issues_labels_dup_label_name_idx on gha_issues_labels(dup_label_name)")
	}

	// gha_forkees
	// Table details and analysis in `analysis/analysis.txt` and `analysis/forkee_*.json`
	// variable
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_forkees")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_forkees("+
					"id bigint not null, "+
					"event_id bigint not null, "+
					"name varchar(80) not null, "+
					"full_name varchar(200) not null, "+
					"owner_id bigint not null, "+
					"description text, "+
					"fork boolean not null, "+
					"created_at {{ts}} not null, "+
					"updated_at {{ts}} not null, "+
					"pushed_at {{ts}}, "+
					"homepage text, "+
					"size int not null, "+
					"stargazers_count int not null, "+
					"has_issues boolean not null, "+
					"has_projects boolean, "+
					"has_downloads boolean not null, "+
					"has_wiki boolean not null, "+
					"has_pages boolean, "+
					"forks int not null, "+
					"open_issues int not null, "+
					"watchers int not null, "+
					"default_branch varchar(200) not null, "+
					"public boolean, "+
					"language varchar(80), "+
					"organization varchar(100), "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"dup_owner_login varchar(120) not null, "+
					"primary key(id, event_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index forkees_event_id_idx on gha_forkees(event_id)")
		ExecSQLWithErr(c, ctx, "create index forkees_owner_id_idx on gha_forkees(owner_id)")
		ExecSQLWithErr(c, ctx, "create index forkees_created_at_idx on gha_forkees(created_at)")
		ExecSQLWithErr(c, ctx, "create index forkees_updated_at_idx on gha_forkees(updated_at)")
		ExecSQLWithErr(c, ctx, "create index forkees_dup_actor_id_idx on gha_forkees(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index forkees_dup_actor_login_idx on gha_forkees(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index forkees_dup_repo_id_idx on gha_forkees(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index forkees_dup_repo_name_idx on gha_forkees(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index forkees_dup_type_idx on gha_forkees(dup_type)")
		ExecSQLWithErr(c, ctx, "create index forkees_dup_created_at_idx on gha_forkees(dup_created_at)")
		ExecSQLWithErr(c, ctx, "create index forkees_dup_owner_login_idx on gha_forkees(dup_owner_login)")
		ExecSQLWithErr(c, ctx, "create index forkees_language_idx on gha_forkees(language)")
		ExecSQLWithErr(c, ctx, "create index forkees_organization_idx on gha_forkees(organization)")
	}

	// gha_releases
	// Table details and analysis in `analysis/analysis.txt` and `analysis/release_*.json`
	// Key: author_id
	// Array: assets
	// variable
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_releases")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_releases("+
					"id bigint not null, "+
					"event_id bigint not null, "+
					"tag_name varchar(200) not null, "+
					"target_commitish varchar(200) not null, "+
					"name varchar(200), "+
					"draft boolean not null, "+
					"author_id bigint not null, "+
					"prerelease boolean not null, "+
					"created_at {{ts}} not null, "+
					"published_at {{ts}}, "+
					"body text, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"dup_author_login varchar(120) not null, "+
					"primary key(id, event_id)"+
					")",
			),
		)
		// variable
		ExecSQLWithErr(c, ctx, "drop table if exists gha_releases_assets")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_releases_assets("+
					"release_id bigint not null, "+
					"event_id bigint not null, "+
					"asset_id bigint not null, "+
					"primary key(release_id, event_id, asset_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index releases_event_id_idx on gha_releases(event_id)")
		ExecSQLWithErr(c, ctx, "create index releases_author_id_idx on gha_releases(author_id)")
		ExecSQLWithErr(c, ctx, "create index releases_created_at_idx on gha_releases(created_at)")
		ExecSQLWithErr(c, ctx, "create index releases_dup_actor_id_idx on gha_releases(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index releases_dup_actor_login_idx on gha_releases(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index releases_dup_repo_id_idx on gha_releases(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index releases_dup_repo_name_idx on gha_releases(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index releases_dup_type_idx on gha_releases(dup_type)")
		ExecSQLWithErr(c, ctx, "create index releases_dup_created_at_idx on gha_releases(dup_created_at)")
		ExecSQLWithErr(c, ctx, "create index releases_dup_author_login_idx on gha_releases(dup_author_login)")
	}

	// gha_assets
	// Table details and analysis in `analysis/analysis.txt` and `analysis/asset_*.json`
	// Key: uploader_id
	// variable
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_assets")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_assets("+
					"id bigint not null, "+
					"event_id bigint not null, "+
					"name varchar(200) not null, "+
					"label varchar(120), "+
					"uploader_id bigint not null, "+
					"content_type varchar(80) not null, "+
					"state varchar(20) not null, "+
					"size int not null, "+
					"download_count int not null, "+
					"created_at {{ts}} not null, "+
					"updated_at {{ts}} not null, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"dup_uploader_login varchar(120) not null, "+
					"primary key(id, event_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index assets_event_id_idx on gha_assets(event_id)")
		ExecSQLWithErr(c, ctx, "create index assets_uploader_id_idx on gha_assets(uploader_id)")
		ExecSQLWithErr(c, ctx, "create index assets_content_type_idx on gha_assets(content_type)")
		ExecSQLWithErr(c, ctx, "create index assets_state_idx on gha_assets(state)")
		ExecSQLWithErr(c, ctx, "create index assets_created_at_idx on gha_assets(created_at)")
		ExecSQLWithErr(c, ctx, "create index assets_updated_at_idx on gha_assets(updated_at)")
		ExecSQLWithErr(c, ctx, "create index assets_dup_actor_id_idx on gha_assets(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index assets_dup_actor_login_idx on gha_assets(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index assets_dup_repo_id_idx on gha_assets(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index assets_dup_repo_name_idx on gha_assets(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index assets_dup_type_idx on gha_assets(dup_type)")
		ExecSQLWithErr(c, ctx, "create index assets_dup_created_at_idx on gha_assets(dup_created_at)")
		ExecSQLWithErr(c, ctx, "create index assets_dup_uploader_login_idx on gha_assets(dup_uploader_login)")
	}

	// gha_pull_requests
	// Table details and analysis in `analysis/analysis.txt` and `analysis/pull_request_*.json`
	// Keys: actor: user_id, branch: base_sha, head_sha
	// Nullable keys: actor: merged_by_id, assignee_id, milestone: milestone_id
	// Arrays: actors: assignees, requested_reviewers
	// variable
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_pull_requests")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_pull_requests("+
					"id bigint not null, "+
					"event_id bigint not null, "+
					"user_id bigint not null, "+
					"base_sha varchar(40) not null, "+
					"head_sha varchar(40) not null, "+
					"merged_by_id bigint, "+
					"assignee_id bigint, "+
					"milestone_id bigint, "+
					"number int not null, "+
					"state varchar(20) not null, "+
					"locked boolean, "+
					"title text not null, "+
					"body text, "+
					"created_at {{ts}} not null, "+
					"updated_at {{ts}} not null, "+
					"closed_at {{ts}}, "+
					"merged_at {{ts}}, "+
					"merge_commit_sha varchar(40), "+
					"merged boolean, "+
					"mergeable boolean, "+
					"rebaseable boolean, "+
					"mergeable_state varchar(20), "+
					"comments int, "+
					"review_comments int, "+
					"maintainer_can_modify boolean, "+
					"commits int, "+
					"additions int, "+
					"deletions int, "+
					"changed_files int, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"dup_user_login varchar(120) not null, "+
					"dupn_assignee_login varchar(120), "+
					"dupn_merged_by_login varchar(120), "+
					"primary key(id, event_id)"+
					")",
			),
		)
		// variable
		ExecSQLWithErr(c, ctx, "drop table if exists gha_pull_requests_assignees")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_pull_requests_assignees("+
					"pull_request_id bigint not null, "+
					"event_id bigint not null, "+
					"assignee_id bigint not null, "+
					"primary key(pull_request_id, event_id, assignee_id)"+
					")",
			),
		)
		// variable
		ExecSQLWithErr(c, ctx, "drop table if exists gha_pull_requests_requested_reviewers")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_pull_requests_requested_reviewers("+
					"pull_request_id bigint not null, "+
					"event_id bigint not null, "+
					"requested_reviewer_id bigint not null, "+
					"primary key(pull_request_id, event_id, requested_reviewer_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index pull_requests_event_id_idx on gha_pull_requests(event_id)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_user_id_idx on gha_pull_requests(user_id)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_base_sha_idx on gha_pull_requests(base_sha)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_head_sha_idx on gha_pull_requests(head_sha)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_merged_by_id_idx on gha_pull_requests(merged_by_id)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_assignee_id_idx on gha_pull_requests(assignee_id)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_milestone_id_idx on gha_pull_requests(milestone_id)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_state_idx on gha_pull_requests(state)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_created_at_idx on gha_pull_requests(created_at)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_updated_at_idx on gha_pull_requests(updated_at)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_closed_at_idx on gha_pull_requests(closed_at)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_merged_at_idx on gha_pull_requests(merged_at)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_dup_actor_id_idx on gha_pull_requests(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_dup_actor_login_idx on gha_pull_requests(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_dup_repo_id_idx on gha_pull_requests(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_dup_repo_name_idx on gha_pull_requests(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_dup_type_idx on gha_pull_requests(dup_type)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_dup_created_at_idx on gha_pull_requests(dup_created_at)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_dup_user_login_idx on gha_pull_requests(dup_user_login)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_dupn_assignee_login_idx on gha_pull_requests(dupn_assignee_login)")
		ExecSQLWithErr(c, ctx, "create index pull_requests_dupn_merged_by_login_idx on gha_pull_requests(dupn_merged_by_login)")
	}

	// gha_branches
	// Table details and analysis in `analysis/analysis.txt` and `analysis/branch_*.json`
	// Nullable keys: forkee: repo_id, actor: user_id
	// variable
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_branches")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_branches("+
					"sha varchar(40) not null, "+
					"event_id bigint not null, "+
					"user_id bigint, "+
					"repo_id bigint, "+
					"label varchar(200) not null, "+
					"ref varchar(200) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"dupn_forkee_name varchar(160), "+
					"dupn_user_login varchar(120), "+
					"primary key(sha, event_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index branches_event_id_idx on gha_branches(event_id)")
		ExecSQLWithErr(c, ctx, "create index branches_user_id_idx on gha_branches(user_id)")
		ExecSQLWithErr(c, ctx, "create index branches_repo_id_idx on gha_branches(repo_id)")
		ExecSQLWithErr(c, ctx, "create index branches_dupn_user_login_idx on gha_branches(dupn_user_login)")
		ExecSQLWithErr(c, ctx, "create index branches_dupn_forkee_name_idx on gha_branches(dupn_forkee_name)")
		ExecSQLWithErr(c, ctx, "create index branches_dup_type_idx on gha_branches(dup_type)")
		ExecSQLWithErr(c, ctx, "create index branches_dup_created_at_idx on gha_branches(dup_created_at)")
	}

	// gha_teams
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_teams")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_teams("+
					"id bigint not null, "+
					"event_id bigint not null, "+
					"name varchar(120) not null, "+
					"slug varchar(100) not null, "+
					"permission varchar(20) not null, "+
					"dup_actor_id bigint not null, "+
					"dup_actor_login varchar(120) not null, "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"primary key(id, event_id)"+
					")",
			),
		)
		// variable
		ExecSQLWithErr(c, ctx, "drop table if exists gha_teams_repositories")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_teams_repositories("+
					"team_id bigint not null, "+
					"event_id bigint not null, "+
					"repository_id bigint not null, "+
					"primary key(team_id, event_id, repository_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index teams_event_id_idx on gha_teams(event_id)")
		ExecSQLWithErr(c, ctx, "create index teams_name_idx on gha_teams(name)")
		ExecSQLWithErr(c, ctx, "create index teams_slug_idx on gha_teams(slug)")
		ExecSQLWithErr(c, ctx, "create index teams_permission_idx on gha_teams(permission)")
		ExecSQLWithErr(c, ctx, "create index teams_dup_actor_id_idx on gha_teams(dup_actor_id)")
		ExecSQLWithErr(c, ctx, "create index teams_dup_actor_login_idx on gha_teams(dup_actor_login)")
		ExecSQLWithErr(c, ctx, "create index teams_dup_repo_id_idx on gha_teams(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index teams_dup_repo_name_idx on gha_teams(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index teams_dup_type_idx on gha_teams(dup_type)")
		ExecSQLWithErr(c, ctx, "create index teams_dup_created_at_idx on gha_teams(dup_created_at)")
	}

	// Logs table (recently this table moved to separate database `devstats` to separate logs
	// But all gha databases still do have this table
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_logs")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_logs("+
					"id {{pkauto}}, "+
					"dt {{tsnow}}, "+
					"prog varchar(32) not null, "+
					"proj varchar(32) not null, "+
					"run_dt {{ts}} not null, "+
					"msg text"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index logs_id_idx on gha_logs(id)")
		ExecSQLWithErr(c, ctx, "create index logs_dt_idx on gha_logs(dt)")
		ExecSQLWithErr(c, ctx, "create index logs_prog_idx on gha_logs(prog)")
		ExecSQLWithErr(c, ctx, "create index logs_proj_idx on gha_logs(proj)")
		ExecSQLWithErr(c, ctx, "create index logs_run_dt_idx on gha_logs(run_dt)")
	}

	// `Commit - file list it refers to` mapping table, used by `get_repos` tool
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_commits_files")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_commits_files("+
					"sha varchar(40) not null, "+
					"path text not null, "+
					"size bigint not null, "+
					"dt {{ts}} not null, "+
					"primary key(sha, path)"+
					")",
			),
		)
		ExecSQLWithErr(c, ctx, "drop table if exists gha_events_commits_files")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_events_commits_files("+
					"sha varchar(40) not null, "+
					"event_id bigint not null, "+
					"path text not null, "+
					"size bigint not null, "+
					"dt {{ts}} not null, "+
					"repo_group varchar(80), "+
					"dup_repo_id bigint not null, "+
					"dup_repo_name varchar(160) not null, "+
					"dup_type varchar(40) not null, "+
					"dup_created_at {{ts}} not null, "+
					"primary key(sha, event_id, path)"+
					")",
			),
		)
		ExecSQLWithErr(c, ctx, "drop table if exists gha_skip_commits")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_skip_commits("+
					"sha varchar(40) not null, "+
					"dt {{ts}} not null, "+
					"primary key(sha)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index commits_files_sha_idx on gha_commits_files(sha)")
		ExecSQLWithErr(c, ctx, "create index commits_files_path_idx on gha_commits_files(path)")
		ExecSQLWithErr(c, ctx, "create index commits_files_size_idx on gha_commits_files(size)")
		ExecSQLWithErr(c, ctx, "create index commits_files_dt_idx on gha_commits_files(dt)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_sha_idx on gha_events_commits_files(sha)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_event_id_idx on gha_events_commits_files(event_id)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_path_idx on gha_events_commits_files(path)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_size_idx on gha_events_commits_files(size)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_dt_idx on gha_events_commits_files(dt)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_repo_group_idx on gha_events_commits_files(repo_group)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_dup_repo_id_idx on gha_events_commits_files(dup_repo_id)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_dup_repo_name_idx on gha_events_commits_files(dup_repo_name)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_dup_type_idx on gha_events_commits_files(dup_type)")
		ExecSQLWithErr(c, ctx, "create index events_commits_files_dup_created_at_idx on gha_events_commits_files(dup_created_at)")
		ExecSQLWithErr(c, ctx, "create index skip_commits_sha_idx on gha_skip_commits(sha)")
	}

	// Scripts to run on a given database
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_postprocess_scripts")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_postprocess_scripts("+
					"ord int not null, "+
					"path text not null, "+
					"primary key(ord, path)"+
					")",
			),
		)
	}

	// This table is a kind of `materialized view` of all texts
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_texts")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_texts("+
					"event_id bigint, "+
					"body text, "+
					"created_at {{ts}} not null, "+
					"actor_id bigint not null, "+
					"actor_login varchar(120) not null, "+
					"repo_id bigint not null, "+
					"repo_name varchar(160) not null, "+
					"type varchar(40) not null"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index texts_event_id_idx on gha_texts(event_id)")
		ExecSQLWithErr(c, ctx, "create index texts_created_at_idx on gha_texts(created_at)")
		ExecSQLWithErr(c, ctx, "create index texts_actor_id_idx on gha_texts(actor_id)")
		ExecSQLWithErr(c, ctx, "create index texts_actor_login_idx on gha_texts(actor_login)")
		ExecSQLWithErr(c, ctx, "create index texts_repo_id_idx on gha_texts(repo_id)")
		ExecSQLWithErr(c, ctx, "create index texts_repo_name_idx on gha_texts(repo_name)")
		ExecSQLWithErr(c, ctx, "create index texts_type_idx on gha_texts(type)")
	}

	// This table is a kind of `materialized view` of issue event labels
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_issues_events_labels")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_issues_events_labels("+
					"issue_id bigint not null, "+
					"event_id bigint not null, "+
					"label_id bigint not null, "+
					"label_name varchar(160) not null, "+
					"created_at {{ts}} not null, "+
					"actor_id bigint not null, "+
					"actor_login varchar(120) not null, "+
					"repo_id bigint not null, "+
					"repo_name varchar(160) not null, "+
					"type varchar(40) not null, "+
					"issue_number int not null, "+
					"primary key(issue_id, event_id, label_id)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(
			c,
			ctx,
			"create index issues_events_labels_issue_id_idx on gha_issues_events_labels(issue_id)",
		)
		ExecSQLWithErr(
			c,
			ctx,
			"create index issues_events_labels_event_id_idx on gha_issues_events_labels(event_id)",
		)
		ExecSQLWithErr(
			c,
			ctx,
			"create index issues_events_labels_label_id_idx on gha_issues_events_labels(label_id)",
		)
		ExecSQLWithErr(
			c,
			ctx,
			"create index issues_events_labels_label_name_idx on gha_issues_events_labels(label_name)",
		)
		ExecSQLWithErr(
			c,
			ctx,
			"create index issues_events_labels_created_at_idx on gha_issues_events_labels(created_at)",
		)
		ExecSQLWithErr(c, ctx, "create index issues_events_labels_actor_id_idx on gha_issues_events_labels(actor_id)")
		ExecSQLWithErr(c, ctx, "create index issues_events_labels_actor_login_idx on gha_issues_events_labels(actor_login)")
		ExecSQLWithErr(c, ctx, "create index issues_events_labels_repo_id_idx on gha_issues_events_labels(repo_id)")
		ExecSQLWithErr(c, ctx, "create index issues_events_labels_repo_name_idx on gha_issues_events_labels(repo_name)")
		ExecSQLWithErr(c, ctx, "create index issues_events_labels_type_idx on gha_issues_events_labels(type)")
		ExecSQLWithErr(c, ctx, "create index issues_events_labels_issue_number_idx on gha_issues_events_labels(issue_number)")
	}

	// This table is a kind of `materialized view` of issues - PRs connections
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_issues_pull_requests")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_issues_pull_requests("+
					"issue_id bigint not null, "+
					"pull_request_id bigint not null, "+
					"number int not null, "+
					"repo_id bigint not null, "+
					"repo_name varchar(160) not null, "+
					"created_at {{ts}} not null"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index issues_pull_requests_issue_id_idx on gha_issues_pull_requests(issue_id)")
		ExecSQLWithErr(c, ctx, "create index issues_pull_requests_pull_request_id_idx on gha_issues_pull_requests(pull_request_id)")
		ExecSQLWithErr(c, ctx, "create index issues_pull_requests_number_idx on gha_issues_pull_requests(number)")
		ExecSQLWithErr(c, ctx, "create index issues_pull_requests_repo_id_idx on gha_issues_pull_requests(repo_id)")
		ExecSQLWithErr(c, ctx, "create index issues_pull_requests_repo_name_idx on gha_issues_pull_requests(repo_name)")
		ExecSQLWithErr(c, ctx, "create index issues_pull_requests_created_at_idx on gha_issues_pull_requests(created_at)")
	}

	// This table holds Postgres variables defined by `vars` tool.
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_vars")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_vars("+
					"name varchar(100), "+
					"value_i bigint, "+
					"value_f double precision, "+
					"value_s text, "+
					"value_dt {{ts}}, "+
					"primary key(name)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index vars_name_idx on gha_vars(name)")
	}
	// This is to determine if a given metric is computed for some period or not
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_computed")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_computed("+
					"metric text not null, "+
					"dt {{ts}} not null, "+
					"primary key(metric, dt)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index computed_metric_idx on gha_computed(metric)")
		ExecSQLWithErr(c, ctx, "create index computed_dt_idx on gha_computed(dt)")
	}
	if ctx.Table {
		ExecSQLWithErr(c, ctx, "drop table if exists gha_parsed")
		ExecSQLWithErr(
			c,
			ctx,
			CreateTable(
				"gha_parsed("+
					"dt {{ts}} not null, "+
					"primary key(dt)"+
					")",
			),
		)
	}
	if ctx.Index {
		ExecSQLWithErr(c, ctx, "create index parsed_dt_idx on gha_parsed(dt)")
	}
	// Foreign keys are not needed - they slow down processing a lot

	// Tools (like views and functions needed for generating metrics)
	if ctx.Tools {
		// Local or cron mode?
		dataPrefix := DataDir
		if ctx.Local {
			dataPrefix = "./"
		}
		// Get list of script files
		rows, err := c.Query("select path from gha_postprocess_scripts order by ord")
		defer func() { FatalOnError(rows.Close()) }()
		FatalOnError(err)
		script := ""
		for rows.Next() {
			dtStart := time.Now()
			FatalOnError(rows.Scan(&script))
			bytes, err := ReadFile(ctx, dataPrefix+script)
			FatalOnError(err)
			sql := string(bytes)
			ExecSQLWithErr(c, ctx, sql)
			if ctx.Debug > 0 {
				dtEnd := time.Now()
				Printf("Executed script: %s: took %v\n", script, dtEnd.Sub(dtStart))
			}
		}
		FatalOnError(rows.Err())
	}
}
