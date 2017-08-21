#!/usr/bin/env ruby

# rubocop:disable Style/GlobalVars
require 'pry'
require './conn' # All database details & setup there
require './mgetc'
$index = ENV['GHA2DB_INDEX'] ? true : false
$table = ENV['GHA2DB_SKIPTABLE'] ? false : true
$tools = ENV['GHA2DB_SKIPTOOLS'] ? false : true

# rubocop:disable Lint/Debugger
def structure
  # Connect to database
  c = conn

  # gha_events
  # {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592,
  # "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592, "org:Hash"=>19451}
  # {"id"=>10, "type"=>29, "actor"=>278, "repo"=>290, "payload"=>216017, "public"=>4,
  # "created_at"=>20, "org"=>230}
  # const
  if $table
    exec_sql(c, 'drop table if exists gha_events')
    exec_sql(
      c,
      create_table(
        'gha_events('\
        'id bigint not null primary key, '\
        'type varchar(40) not null, '\
        'actor_id bigint not null, '\
        'repo_id bigint not null, '\
        'public boolean not null, '\
        'created_at {{ts}} not null, '\
        'org_id bigint, '\
        'actor_login varchar(120) not null, '\
        'repo_name varchar(160) not null'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index events_type_idx on gha_events(type)')
    exec_sql(c, 'create index events_actor_id_idx on gha_events(actor_id)')
    exec_sql(c, 'create index events_repo_id_idx on gha_events(repo_id)')
    exec_sql(c, 'create index events_org_id_idx on gha_events(org_id)')
    exec_sql(c, 'create index events_created_at_idx on gha_events(created_at)')
    exec_sql(c, 'create index events_actor_login_idx on gha_events(actor_login)')
    exec_sql(c, 'create index events_repo_name_idx on gha_events(repo_name)')
  end

  # gha_actors
  # {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592,
  # "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
  # {"id"=>8, "login"=>34, "display_login"=>34, "gravatar_id"=>0, "url"=>63,
  # "avatar_url"=>49}
  # const
  if $table
    exec_sql(c, 'drop table if exists gha_actors')
    exec_sql(
      c,
      create_table(
        'gha_actors('\
        'id bigint not null primary key, '\
        'login varchar(120) not null'\
        ')'
      )
    )
  end
  exec_sql(c, 'create index actors_login_idx on gha_actors(login)') if $index

  # gha_repos
  # {"id:Fixnum"=>48592, "name:String"=>48592, "url:String"=>48592}
  # {"id"=>8, "name"=>111, "url"=>140}
  # const
  if $table
    exec_sql(c, 'drop table if exists gha_repos')
    exec_sql(
      c,
      create_table(
        'gha_repos('\
        'id bigint not null primary key, '\
        'name varchar(160) not null'\
        ')'
      )
    )
  end
  exec_sql(c, 'create index repos_name_idx on gha_repos(name)') if $index

  # gha_orgs
  # {"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494,
  # "url:String"=>18494, "avatar_url:String"=>18494}
  # {"id"=>8, "login"=>38, "gravatar_id"=>0, "url"=>66, "avatar_url"=>49}
  # const
  if $table
    exec_sql(c, 'drop table if exists gha_orgs')
    exec_sql(
      c,
      create_table(
        'gha_orgs('\
        'id bigint not null primary key, '\
        'login varchar(100) not null'\
        ')'
      )
    )
  end
  exec_sql(c, 'create index orgs_login_idx on gha_orgs(login)') if $index

  # gha_payloads
  # {"push_id:Fixnum"=>24636, "size:Fixnum"=>24636, "distinct_size:Fixnum"=>24636,
  # "ref:String"=>30522, "head:String"=>24636, "before:String"=>24636, "commits:Array"=>24636,
  # "action:String"=>14317, "issue:Hash"=>6446, "comment:Hash"=>6055, "ref_type:String"=>8010,
  # "master_branch:String"=>6724, "description:String"=>3701, "pusher_type:String"=>8010,
  # "pull_request:Hash"=>4475, "ref:NilClass"=>2124, "description:NilClass"=>3023,
  # "number:Fixnum"=>2992, "forkee:Hash"=>1211, "pages:Array"=>370,
  # "release:Hash"=>156, "member:Hash"=>219}
  # {"push_id"=>10, "size"=>4, "distinct_size"=>4, "ref"=>110, "head"=>40, "before"=>40,
  # "commits"=>33215, "action"=>9, "issue"=>87776, "comment"=>177917, "ref_type"=>10,
  # "master_branch"=>34, "description"=>3222, "pusher_type"=>4, "pull_request"=>70565,
  # "number"=>5, "forkee"=>6880, "pages"=>855, "release"=>31206, "member"=>1040}
  # 48746
  # const
  if $table
    exec_sql(c, 'drop table if exists gha_payloads')
    exec_sql(
      c,
      create_table(
        'gha_payloads('\
        'event_id bigint not null primary key, '\
        'push_id int, '\
        'size int, '\
        'ref varchar(200), '\
        'head varchar(40), '\
        'befor varchar(40), '\
        'action varchar(20), '\
        'issue_id bigint, '\
        'comment_id bigint, '\
        'ref_type varchar(20), '\
        'master_branch varchar(200), '\
        'description text, '\
        'number int, '\
        'forkee_id bigint, '\
        'release_id bigint, '\
        'member_id bigint'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index payloads_action_idx on gha_payloads(action)')
    exec_sql(c, 'create index payloads_head_idx on gha_payloads(head)')
    exec_sql(c, 'create index payloads_issue_id_idx on gha_payloads(issue_id)')
    exec_sql(c, 'create index payloads_comment_id_idx on gha_payloads(comment_id)')
    exec_sql(c, 'create index payloads_ref_type_idx on gha_payloads(ref_type)')
    exec_sql(c, 'create index payloads_forkee_id_idx on gha_payloads(forkee_id)')
    exec_sql(c, 'create index payloads_release_id_idx on gha_payloads(release_id)')
    exec_sql(c, 'create index payloads_member_id_idx on gha_payloads(member_id)')
  end

  # gha_commits
  # {"sha:String"=>23265, "author:Hash"=>23265, "message:String"=>23265,
  # "distinct:TrueClass"=>21789, "url:String"=>23265, "distinct:FalseClass"=>1476}
  # {"sha"=>40, "author"=>177, "message"=>19005, "distinct"=>5, "url"=>191}
  # author: {"name:String"=>23265, "email:String"=>23265} (only git username/email)
  # author: {"name"=>96, "email"=>95}
  # 23265
  # variable (per event)
  if $table
    exec_sql(c, 'drop table if exists gha_commits')
    exec_sql(
      c,
      create_table(
        'gha_commits('\
        'sha varchar(40) not null, '\
        'event_id bigint not null, '\
        'author_name varchar(160) not null, '\
        'message text not null, '\
        'is_distinct boolean not null, '\
        'primary key(sha, event_id)'\
        ')'
      )
    )
    # variable
    exec_sql(c, 'drop table if exists gha_events_commits')
    exec_sql(
      c,
      create_table(
        'gha_events_commits('\
        'event_id bigint not null, '\
        'sha varchar(40) not null, '\
        'primary key(event_id, sha)'\
        ')'
      )
    )
  end
  exec_sql(c, 'create index commits_event_id_idx on gha_commits(event_id)') if $index

  # gha_pages
  # {"page_name:String"=>370, "title:String"=>370, "summary:NilClass"=>370,
  # "action:String"=>370, "sha:String"=>370, "html_url:String"=>370}
  # {"page_name"=>65, "title"=>65, "summary"=>0, "action"=>7, "sha"=>40, "html_url"=>130}
  # 370
  # variable
  if $table
    exec_sql(c, 'drop table if exists gha_pages')
    exec_sql(
      c,
      create_table(
        'gha_pages('\
        'sha varchar(40) not null, '\
        'event_id bigint not null, '\
        'action varchar(20) not null, '\
        'title varchar(300) not null, '\
        'primary key(sha, event_id, action, title)'\
        ')'
      )
    )
    # variable
    exec_sql(c, 'drop table if exists gha_events_pages')
    exec_sql(
      c,
      create_table(
        'gha_events_pages('\
        'event_id bigint not null, '\
        'sha varchar(40) not null, '\
        'primary key(event_id, sha)'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index pages_event_id_idx on gha_pages(event_id)')
    exec_sql(c, 'create index pages_action_idx on gha_pages(action)')
  end

  # gha_comments
  # Table details and analysis in `analysis/analysis.txt` and `analysis/comment_*.json`
  # Keys: user_id, commit_id, original_commit_id, pull_request_review_id
  # variable
  if $table
    exec_sql(c, 'drop table if exists gha_comments')
    exec_sql(
      c,
      create_table(
        'gha_comments('\
        'id bigint not null primary key, '\
        'event_id bigint not null, '\
        'body text not null, '\
        'created_at {{ts}} not null, '\
        'updated_at {{ts}} not null, '\
        'type varchar(40) not null, '\
        'user_id bigint not null, '\
        'commit_id varchar(40), '\
        'original_commit_id varchar(40), '\
        'diff_hunk text, '\
        'position int, '\
        'original_position int, '\
        'path text, '\
        'pull_request_review_id bigint, '\
        'line int'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index comments_event_id_idx on gha_comments(event_id)')
    exec_sql(c, 'create index comments_type_idx on gha_comments(type)')
    exec_sql(c, 'create index comments_created_at_idx on gha_comments(created_at)')
    exec_sql(c, 'create index comments_user_id_idx on gha_comments(user_id)')
    exec_sql(c, 'create index comments_commit_id_idx on gha_comments(commit_id)')
    exec_sql(
      c,
      'create index comments_pull_request_review_id_idx on gha_comments(pull_request_review_id)'
    )
  end

  # gha_issues
  # Table details and analysis in `analysis/analysis.txt` and `analysis/issue_*.json`
  # Arrays: assignees, labels
  # Keys: assignee_id, milestone_id, user_id
  # variable
  if $table
    exec_sql(c, 'drop table if exists gha_issues')
    exec_sql(
      c,
      create_table(
        'gha_issues('\
        'id bigint not null, '\
        'event_id bigint not null, '\
        'assignee_id bigint, '\
        'body text, '\
        'closed_at {{ts}}, '\
        'comments int not null, '\
        'created_at {{ts}} not null, '\
        'locked boolean not null, '\
        'milestone_id bigint, '\
        'number int not null, '\
        'state varchar(20) not null, '\
        'title text not null, '\
        'updated_at {{ts}} not null, '\
        'user_id bigint not null, '\
        'is_pull_request boolean not null, '\
        'primary key(id, event_id)'\
        ')'
      )
    )
    # variable
    exec_sql(c, 'drop table if exists gha_issues_assignees')
    exec_sql(
      c,
      create_table(
        'gha_issues_assignees('\
        'issue_id bigint not null, '\
        'event_id bigint not null, '\
        'assignee_id bigint not null, '\
        'primary key(issue_id, event_id, assignee_id)'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index issues_event_id_idx on gha_issues(event_id)')
    exec_sql(c, 'create index issues_assignee_id_idx on gha_issues(assignee_id)')
    exec_sql(c, 'create index issues_created_at_idx on gha_issues(created_at)')
    exec_sql(c, 'create index issues_closed_at_idx on gha_issues(closed_at)')
    exec_sql(c, 'create index issues_milestone_id_idx on gha_issues(milestone_id)')
    exec_sql(c, 'create index issues_state_idx on gha_issues(state)')
    exec_sql(c, 'create index issues_user_id_idx on gha_issues(user_id)')
    exec_sql(c, 'create index issues_is_pull_request_idx on gha_issues(is_pull_request)')
  end

  # gha_milestones
  # Table details and analysis in `analysis/analysis.txt` and `analysis/milestone_*.json`
  # Keys: creator_id
  # variable
  if $table
    exec_sql(c, 'drop table if exists gha_milestones')
    exec_sql(
      c,
      create_table(
        'gha_milestones('\
        'id bigint not null, '\
        'event_id bigint not null, '\
        'closed_at {{ts}}, '\
        'closed_issues int not null, '\
        'created_at {{ts}} not null, '\
        'creator_id bigint, '\
        'description text, '\
        'due_on {{ts}}, '\
        'number int not null, '\
        'open_issues int not null, '\
        'state varchar(20) not null, '\
        'title varchar(200) not null, '\
        'updated_at {{ts}} not null, '\
        'primary key(id, event_id)'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index milestones_event_id_idx on gha_milestones(event_id)')
    exec_sql(c, 'create index milestones_created_at_idx on gha_milestones(created_at)')
    exec_sql(c, 'create index milestones_creator_id_idx on gha_milestones(creator_id)')
    exec_sql(c, 'create index milestones_state_idx on gha_milestones(state)')
  end

  # gha_labels
  # Table details and analysis in `analysis/analysis.txt` and `analysis/label_*.json`
  # const
  if $table
    exec_sql(c, 'drop table if exists gha_labels')
    exec_sql(
      c,
      create_table(
        'gha_labels('\
        'id bigint not null primary key, '\
        'name varchar(160) not null, '\
        'color varchar(8) not null, '\
        'is_default boolean'\
        ')'
      )
    )
    # variable
    exec_sql(c, 'drop table if exists gha_issues_labels')
    exec_sql(
      c,
      create_table(
        'gha_issues_labels('\
        'issue_id bigint not null, '\
        'event_id bigint not null, '\
        'label_id bigint not null, '\
        'primary key(issue_id, event_id, label_id)'\
        ')'
      )
    )
  end
  exec_sql(c, 'create index labels_name_idx on gha_labels(name)') if $index

  # gha_forkees
  # Table details and analysis in `analysis/analysis.txt` and `analysis/forkee_*.json`
  # variable
  if $table
    exec_sql(c, 'drop table if exists gha_forkees')
    exec_sql(
      c,
      create_table(
        'gha_forkees('\
        'id bigint not null, '\
        'event_id bigint not null, '\
        'name varchar(80) not null, '\
        'full_name varchar(200) not null, '\
        'owner_id bigint not null, '\
        'description text, '\
        'fork boolean not null, '\
        'created_at {{ts}} not null, '\
        'updated_at {{ts}} not null, '\
        'pushed_at {{ts}} not null, '\
        'homepage text, '\
        'size int not null, '\
        'stargazers_count int not null, '\
        'has_issues boolean not null, '\
        'has_projects boolean, '\
        'has_downloads boolean not null, '\
        'has_wiki boolean not null, '\
        'has_pages boolean, '\
        'forks int not null, '\
        'open_issues int not null, '\
        'watchers int not null, '\
        'default_branch varchar(200) not null, '\
        'public boolean, '\
        'primary key(id, event_id)'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index forkees_event_id_idx on gha_forkees(event_id)')
    exec_sql(c, 'create index forkees_owner_id_idx on gha_forkees(owner_id)')
    exec_sql(c, 'create index forkees_created_at_idx on gha_forkees(created_at)')
  end

  # gha_releases
  # Table details and analysis in `analysis/analysis.txt` and `analysis/release_*.json`
  # Key: author_id
  # Array: assets
  # variable
  if $table
    exec_sql(c, 'drop table if exists gha_releases')
    exec_sql(
      c,
      create_table(
        'gha_releases('\
        'id bigint not null, '\
        'event_id bigint not null, '\
        'tag_name varchar(200) not null, '\
        'target_commitish varchar(200) not null, '\
        'name varchar(200), '\
        'draft boolean not null, '\
        'author_id bigint not null, '\
        'prerelease boolean not null, '\
        'created_at {{ts}} not null, '\
        'published_at {{ts}} not null, '\
        'body text, '\
        'primary key(id, event_id)'\
        ')'
      )
    )
    # variable
    exec_sql(c, 'drop table if exists gha_releases_assets')
    exec_sql(
      c,
      create_table(
        'gha_releases_assets('\
        'release_id bigint not null, '\
        'event_id bigint not null, '\
        'asset_id bigint not null, '\
        'primary key(release_id, event_id, asset_id)'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index releases_event_id_idx on gha_releases(event_id)')
    exec_sql(c, 'create index releases_author_id_idx on gha_releases(author_id)')
    exec_sql(c, 'create index releases_created_at_idx on gha_releases(created_at)')
  end

  # gha_assets
  # Table details and analysis in `analysis/analysis.txt` and `analysis/asset_*.json`
  # Key: uploader_id
  # variable
  if $table
    exec_sql(c, 'drop table if exists gha_assets')
    exec_sql(
      c,
      create_table(
        'gha_assets('\
        'id bigint not null, '\
        'event_id bigint not null, '\
        'name varchar(200) not null, '\
        'label varchar(120), '\
        'uploader_id bigint not null, '\
        'content_type varchar(80) not null, '\
        'state varchar(20) not null, '\
        'size int not null, '\
        'download_count int not null, '\
        'created_at {{ts}} not null, '\
        'updated_at {{ts}} not null, '\
        'primary key(id, event_id)'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index assets_event_id_idx on gha_assets(event_id)')
    exec_sql(c, 'create index assets_uploader_id_idx on gha_assets(uploader_id)')
    exec_sql(c, 'create index assets_content_type_idx on gha_assets(content_type)')
    exec_sql(c, 'create index assets_state_idx on gha_assets(state)')
    exec_sql(c, 'create index assets_created_at_idx on gha_assets(created_at)')
  end

  # gha_pull_requests
  # Table details and analysis in `analysis/analysis.txt` and `analysis/pull_request_*.json`
  # Keys: actor: user_id, branch: base_sha, head_sha
  # Nullable keys: actor: merged_by_id, assignee_id, milestone: milestone_id
  # Arrays: actors: assignees, requested_reviewers
  # variable
  if $table
    exec_sql(c, 'drop table if exists gha_pull_requests')
    exec_sql(
      c,
      create_table(
        'gha_pull_requests('\
        'id bigint not null, '\
        'event_id bigint not null, '\
        'user_id bigint not null, '\
        'base_sha varchar(40) not null, '\
        'head_sha varchar(40) not null, '\
        'merged_by_id bigint, '\
        'assignee_id bigint, '\
        'milestone_id bigint, '\
        'number int not null, '\
        'state varchar(20) not null, '\
        'locked boolean not null, '\
        'title text not null, '\
        'body text, '\
        'created_at {{ts}} not null, '\
        'updated_at {{ts}} not null, '\
        'closed_at {{ts}}, '\
        'merged_at {{ts}}, '\
        'merge_commit_sha varchar(40), '\
        'merged boolean, '\
        'mergeable boolean, '\
        'rebaseable boolean, '\
        'mergeable_state varchar(20), '\
        'comments int, '\
        'review_comments int, '\
        'maintainer_can_modify boolean, '\
        'commits int, '\
        'additions int, '\
        'deletions int, '\
        'changed_files int, '\
        'primary key(id, event_id)'\
        ')'
      )
    )
    # variable
    exec_sql(c, 'drop table if exists gha_pull_requests_assignees')
    exec_sql(
      c,
      create_table(
        'gha_pull_requests_assignees('\
        'pull_request_id bigint not null, '\
        'event_id bigint not null, '\
        'assignee_id bigint not null, '\
        'primary key(pull_request_id, event_id, assignee_id)'\
       ')'
      )
    )
    # variable
    exec_sql(c, 'drop table if exists gha_pull_requests_requested_reviewers')
    exec_sql(
      c,
      create_table(
        'gha_pull_requests_requested_reviewers('\
        'pull_request_id bigint not null, '\
        'event_id bigint not null, '\
        'requested_reviewer_id bigint not null, '\
        'primary key(pull_request_id, event_id, requested_reviewer_id)'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index pull_requests_event_id_idx on gha_pull_requests(event_id)')
    exec_sql(c, 'create index pull_requests_user_id_idx on gha_pull_requests(user_id)')
    exec_sql(c, 'create index pull_requests_base_sha_idx on gha_pull_requests(base_sha)')
    exec_sql(c, 'create index pull_requests_head_sha_idx on gha_pull_requests(head_sha)')
    exec_sql(c, 'create index pull_requests_merged_by_id_idx on gha_pull_requests(merged_by_id)')
    exec_sql(c, 'create index pull_requests_assignee_id_idx on gha_pull_requests(assignee_id)')
    exec_sql(c, 'create index pull_requests_milestone_id_idx on gha_pull_requests(milestone_id)')
    exec_sql(c, 'create index pull_requests_state_idx on gha_pull_requests(state)')
    exec_sql(c, 'create index pull_requests_created_at_idx on gha_pull_requests(created_at)')
    exec_sql(c, 'create index pull_requests_closed_at_idx on gha_pull_requests(closed_at)')
    exec_sql(c, 'create index pull_requests_merged_at_idx on gha_pull_requests(merged_at)')
  end

  # gha_branches
  # Table details and analysis in `analysis/analysis.txt` and `analysis/branch_*.json`
  # Nullable keys: forkee: repo_id, actor: user_id
  # variable
  if $table
    exec_sql(c, 'drop table if exists gha_branches')
    exec_sql(
      c,
      create_table(
        'gha_branches('\
        'sha varchar(40) not null, '\
        'event_id bigint not null, '\
        'user_id bigint, '\
        'repo_id bigint, '\
        'label varchar(200) not null, '\
        'ref varchar(200) not null, '\
        'primary key(sha, event_id)'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index branches_event_id_idx on gha_branches(event_id)')
    exec_sql(c, 'create index branches_user_id_idx on gha_branches(user_id)')
    exec_sql(c, 'create index branches_repo_id_idx on gha_branches(repo_id)')
  end

  # This table is a kind of `materialized view` of all texts
  if $table
    exec_sql(c, 'drop table if exists gha_texts')
    exec_sql(
      c,
      create_table(
        'gha_texts('\
        'event_id bigint, '\
        'body text, '\
        'created_at {{ts}} not null'\
        ')'
      )
    )
  end
  if $index
    exec_sql(c, 'create index texts_event_id_idx on gha_texts(event_id)')
    exec_sql(c, 'create index texts_created_at_idx on gha_texts(created_at)')
  end

  # This table is a kind of `materialized view` of issue event labels
  if $table
    exec_sql(c, 'drop table if exists gha_issues_events_labels')
    exec_sql(
      c,
      create_table(
        'gha_issues_events_labels('\
        'issue_id bigint not null, '\
        'event_id bigint not null, '\
        'label_id bigint not null, '\
        'label_name varchar(160) not null, '\
        'created_at {{ts}} not null'\
        ')'
      )
    )
  end
  if $index
    exec_sql(
      c,
      'create index issues_events_labels_issue_id_idx on gha_issues_events_labels(issue_id)'
    )
    exec_sql(
      c,
      'create index issues_events_labels_event_id_idx on gha_issues_events_labels(event_id)'
    )
    exec_sql(
      c,
      'create index issues_events_labels_label_id_idx on gha_issues_events_labels(label_id)'
    )
    exec_sql(
      c,
      'create index issues_events_labels_label_name_idx on gha_issues_events_labels(label_name)'
    )
    exec_sql(
      c,
      'create index issues_events_labels_created_at_idx on gha_issues_events_labels(created_at)'
    )
  end
  # Foreign keys are not needed - they slow down processing a lweek

  # Tools (like views and functions needed for generating metrics)
  if $tools
    # Get max event_id from gha_texts
    r = exec_sql(
      c,
      'select max(event_id) as max_event_id '\
      'from gha_texts'
    )
    max_event_id = 0
    max_event_id = "'#{r.first['max_event_id']}'" if r.first['max_event_id']

    # Add texts to gha_texts table (or fill it initially)
    exec_sql(
      c,
      'insert into gha_texts(event_id, body, created_at) '\
      'select event_id, body, created_at from gha_comments '\
      "where body != '' and event_id > #{max_event_id} union "\
      'select c.event_id, c.message, e.created_at from gha_commits c, gha_events e '\
      "where c.event_id = e.id and c.message != '' and e.id > #{max_event_id} union "\
      'select event_id, title, created_at from gha_issues where '\
      "title != '' and event_id > #{max_event_id}  union "\
      'select event_id, body, created_at from gha_issues where '\
      "body != '' and event_id > #{max_event_id} union "\
      'select event_id, title, created_at from gha_pull_requests where '\
      "title != '' and event_id > #{max_event_id} union "\
      'select event_id, body, created_at from gha_pull_requests '\
      "where body != '' and event_id > #{max_event_id}"
    )

    # Get max event_id from gha_issues_events_labels
    r = exec_sql(
      c,
      'select max(event_id) as max_event_id '\
      'from gha_issues_events_labels'
    )
    max_event_id = 0
    max_event_id = "'#{r.first['max_event_id']}'" if r.first['max_event_id']

    # Add data to gha_issues_events_labels table (or fill it initially)
    exec_sql(
      c,
      'insert into gha_issues_events_labels('\
      'issue_id, event_id, label_id, label_name, created_at) '\
      'select il.issue_id, ev.id, lb.id, lb.name, ev.created_at '\
      'from gha_issues_labels il, gha_events ev, gha_labels lb '\
      "where ev.id = il.event_id and il.label_id = lb.id and ev.id > #{max_event_id}"
    )
  end
rescue $DBError => e
  puts e.message
  binding.pry
ensure
  c&.close
  puts 'Done'
end
# rubocop:enable Lint/Debugger

unless ENV['GHA2DB_SKIPTABLE']
  puts 'This program will recreate DB structure (dropping all existing data)'
end
print 'Continue? (y/n) '
c = mgetc
puts "\n"
structure if c == 'y'

# rubocop:enable Style/GlobalVars
