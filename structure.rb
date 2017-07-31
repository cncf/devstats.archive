#!/usr/bin/env ruby

require 'pg'
require 'pry'
require './mgetc'

# DB setup:
# apt-get install postgresql
#
# sudo -i -u postgres
# psql
# create database gha;
# create user gha_admin with password '<<your_password_here>>';
# grant all privileges on database "gha" to gha_admin;

# Defaults are:
# Database host: environment variable PG_HOST or `localhost`
# Database port: PG_PORT or 5432
# Database name: PG_DB or 'gha'
# Database user: PG_USER or 'gha_admin'
# Database password: PG_PASS || 'password'

def structure
  c = PG::Connection.new(
    host: ENV['PG_HOST'] || 'localhost',
    port: (ENV['PG_PORT'] || '5432').to_i,
    dbname: ENV['PG_DB'] || 'gha',
    user: ENV['PG_USER'] || 'gha_admin',
    password: ENV['PG_PASS'] || 'password'
  )
  puts 'Connected'
  # gha_events
  # {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592, "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592, "org:Hash"=>19451}
  # {"id"=>10, "type"=>29, "actor"=>278, "repo"=>290, "payload"=>216017, "public"=>4, "created_at"=>20, "org"=>230}
  # const
  c.exec('drop table if exists gha_events')
  c.exec(
    'create table gha_events(' +
    'id bigint not null primary key, ' +
    'type varchar(40) not null, ' +
    'actor_id bigint not null, ' +
    'repo_id bigint not null, ' +
    'public boolean not null, ' +
    'created_at timestamp not null, ' +
    'org_id bigint' +
    ')'
  )
  # gha_actors
  # {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592, "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
  # {"id"=>8, "login"=>34, "display_login"=>34, "gravatar_id"=>0, "url"=>63, "avatar_url"=>49}
  # const
  c.exec('drop table if exists gha_actors')
  c.exec(
    'create table gha_actors(' +
    'id bigint not null primary key, ' +
    'login varchar(120) not null' +
    ')'
  )
  # gha_repos
  # {"id:Fixnum"=>48592, "name:String"=>48592, "url:String"=>48592}
  # {"id"=>8, "name"=>111, "url"=>140}
  # const
  c.exec('drop table if exists gha_repos')
  c.exec(
    'create table gha_repos(' +
    'id bigint not null primary key, ' +
    'name varchar(160) not null' +
    ')'
  )

  # gha_orgs
  # {"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494, "url:String"=>18494, "avatar_url:String"=>18494}
  # {"id"=>8, "login"=>38, "gravatar_id"=>0, "url"=>66, "avatar_url"=>49}
  # const
  c.exec('drop table if exists gha_orgs')
  c.exec(
    'create table gha_orgs(' +
    'id bigint not null primary key, ' +
    'login varchar(100) not null' +
    ')'
  )

  # gha_payloads
  # {"push_id:Fixnum"=>24636, "size:Fixnum"=>24636, "distinct_size:Fixnum"=>24636, "ref:String"=>30522, "head:String"=>24636, "before:String"=>24636, "commits:Array"=>24636, "action:String"=>14317, "issue:Hash"=>6446, "comment:Hash"=>6055, "ref_type:String"=>8010, "master_branch:String"=>6724, "description:String"=>3701, "pusher_type:String"=>8010, "pull_request:Hash"=>4475, "ref:NilClass"=>2124, "description:NilClass"=>3023, "number:Fixnum"=>2992, "forkee:Hash"=>1211, "pages:Array"=>370, "release:Hash"=>156, "member:Hash"=>219}
  # {"push_id"=>10, "size"=>4, "distinct_size"=>4, "ref"=>110, "head"=>40, "before"=>40, "commits"=>33215, "action"=>9, "issue"=>87776, "comment"=>177917, "ref_type"=>10, "master_branch"=>34, "description"=>3222, "pusher_type"=>4, "pull_request"=>70565, "number"=>5, "forkee"=>6880, "pages"=>855, "release"=>31206, "member"=>1040}
  # 48746
  # const
  c.exec('drop table if exists gha_payloads')
  c.exec(
    'create table gha_payloads(' +
    'event_id bigint not null primary key, ' +
    'push_id int, ' +
    'size int, ' +
    'ref varchar(200), ' +
    'head varchar(40), ' +
    'before varchar(40), ' +
    'action varchar(20), ' +
    'issue_id bigint, ' +
    'comment_id bigint, ' +
    'ref_type varchar(20), ' +
    'master_branch varchar(200), ' +
    'description text, ' +
    'number int, ' +
    'forkee_id bigint, ' +
    'release_id bigint, ' +
    'member_id bigint' +
    ')'
  )

  # gha_commits
  # {"sha:String"=>23265, "author:Hash"=>23265, "message:String"=>23265, "distinct:TrueClass"=>21789, "url:String"=>23265, "distinct:FalseClass"=>1476}
  # {"sha"=>40, "author"=>177, "message"=>19005, "distinct"=>5, "url"=>191}
  # author: {"name:String"=>23265, "email:String"=>23265} (only git username/email)
  # author: {"name"=>96, "email"=>95}
  # 23265
  # variable (per event)
  c.exec('drop table if exists gha_commits')
  c.exec(
    'create table gha_commits(' +
    'sha varchar(40) not null, ' +
    'event_id bigint not null, ' +
    'author_name varchar(160) not null, ' +
    'message text not null, ' +
    'is_distinct boolean not null, ' +
    'primary key(sha, event_id)' +
    ')'
  )
  # variable
  c.exec('drop table if exists gha_events_commits')
  c.exec(
    'create table gha_events_commits(' +
    'event_id bigint not null, ' +
    'sha varchar(40) not null, ' +
    'primary key(event_id, sha)' +
    ')'
  )

  # gha_pages
  # {"page_name:String"=>370, "title:String"=>370, "summary:NilClass"=>370, "action:String"=>370, "sha:String"=>370, "html_url:String"=>370}
  # {"page_name"=>65, "title"=>65, "summary"=>0, "action"=>7, "sha"=>40, "html_url"=>130}
  # 370
  # variable
  c.exec('drop table if exists gha_pages')
  c.exec(
    'create table gha_pages(' +
    'sha varchar(40) not null, ' +
    'event_id bigint not null, ' +
    'action varchar(20) not null, ' +
    'title varchar(300) not null, ' +
    'primary key(sha, event_id, action, title)' +
    ')'
  )
  # variable
  c.exec('drop table if exists gha_events_pages')
  c.exec(
    'create table gha_events_pages(' +
    'event_id bigint not null, ' +
    'sha varchar(40) not null, ' +
    'primary key(event_id, sha)' +
    ')'
  )

  # gha_comments
  # Table details and analysis in `analysis/analysis.txt` and `analysis/comment_*.json`
  # Keys: user_id, commit_id, original_commit_id, pull_request_review_id
  # const & per event
  c.exec('drop table if exists gha_comments')
  c.exec(
    'create table gha_comments(' +
    'id bigint not null primary key, ' +
    # 'event_id bigint not null, ' +
    'body text not null, ' +
    'created_at timestamp not null, ' +
    'updated_at timestamp not null, ' +
    'type varchar(40) not null, ' +
    'user_id bigint not null, ' +
    'commit_id varchar(40), ' +
    'original_commit_id varchar(40), ' +
    'diff_hunk text, ' +
    'position int, ' +
    'original_position int, ' +
    'path text, ' +
    'pull_request_review_id bigint, ' +
    'line int' +
    ')'
  )

  # gha_issues
  # Table details and analysis in `analysis/analysis.txt` and `analysis/issue_*.json`
  # Arrays: assignees, labels
  # Keys: assignee_id, milestone_id, user_id
  # NOTICE: We are skipoping pull_request Hash there because it contains only URL links!
  # variable
  c.exec('drop table if exists gha_issues')
  c.exec(
    'create table gha_issues(' +
    'id bigint not null, ' +
    'event_id bigint not null, ' +
    'assignee_id bigint, ' +
    'body text, ' +
    'closed_at timestamp, ' +
    'comments int not null, ' +
    'created_at timestamp not null, ' +
    'locked boolean not null, ' +
    'milestone_id bigint, ' +
    'number int not null, ' +
    'state varchar(20) not null, ' +
    'title text not null, ' +
    'updated_at timestamp not null, ' +
    'user_id bigint not null, ' +
    'primary key(id, event_id)' +
    ')'
  )
  # variable
  c.exec('drop table if exists gha_issues_assignees')
  c.exec(
    'create table gha_issues_assignees(' +
    'issue_id bigint not null, ' +
    'event_id bigint not null, ' +
    'assignee_id bigint not null, ' +
    'primary key(issue_id, event_id, assignee_id)' +
    ')'
  )

  # gha_milestones
  # Table details and analysis in `analysis/analysis.txt` and `analysis/milestone_*.json`
  # Keys: creator_id
  # variable
  c.exec('drop table if exists gha_milestones')
  c.exec(
    'create table gha_milestones(' +
    'id bigint not null, ' +
    'event_id bigint not null, ' +
    'closed_at timestamp, ' +
    'closed_issues int not null, ' +
    'created_at timestamp not null, ' +
    'creator_id bigint, ' +
    'description text, ' +
    'due_on timestamp, ' +
    'number int not null, ' +
    'open_issues int not null, ' +
    'state varchar(20) not null, ' +
    'title varchar(200) not null, ' +
    'updated_at timestamp not null, ' +
    'primary key(id, event_id)' +
    ')'
  )

  # gha_labels
  # Table details and analysis in `analysis/analysis.txt` and `analysis/label_*.json`
  # const
  c.exec('drop table if exists gha_labels')
  c.exec(
    'create table gha_labels(' +
    'id bigint not null primary key, ' +
    'name varchar(160) not null, ' +
    'color varchar(8) not null, ' +
    'is_default boolean not null' +
    ')'
  )
  # variable
  c.exec('drop table if exists gha_issues_labels')
  c.exec(
    'create table gha_issues_labels(' +
    'issue_id bigint not null, ' +
    'event_id bigint not null, ' +
    'label_id bigint not null, ' +
    'primary key(issue_id, event_id, label_id)' +
    ')'
  )

  # gha_forkees
  # Table details and analysis in `analysis/analysis.txt` and `analysis/forkee_*.json`
  # variable
  c.exec('drop table if exists gha_forkees')
  c.exec(
    'create table gha_forkees(' +
    'id bigint not null, ' +
    'event_id bigint not null, ' +
    'name varchar(80) not null, ' +
    'full_name varchar(200) not null, ' +
    'owner_id bigint not null, ' +
    'description text, ' +
    'fork boolean not null, ' +
    'created_at timestamp not null, ' +
    'updated_at timestamp not null, ' +
    'pushed_at timestamp not null, ' +
    'homepage text, ' +
    'size int not null, ' +
    'stargazers_count int not null, ' +
    'has_issues boolean not null, ' +
    'has_projects boolean, ' +
    'has_downloads boolean not null, ' +
    'has_wiki boolean not null, ' +
    'has_pages boolean not null, ' +
    'forks int not null, ' +
    'open_issues int not null, ' +
    'watchers int not null, ' +
    'default_branch varchar(200) not null, ' +
    'public boolean, ' +
    'primary key(id, event_id)' +
    ')'
  )

  # gha_releases
  # Table details and analysis in `analysis/analysis.txt` and `analysis/release_*.json`
  # Key: author_id
  # Array: assets
  # variable
  c.exec('drop table if exists gha_releases')
  c.exec(
    'create table gha_releases(' +
    'id bigint not null, ' +
    'event_id bigint not null, ' +
    'tag_name varchar(200) not null, ' +
    'target_commitish varchar(200) not null, ' +
    'name varchar(200), ' +
    'draft boolean not null, ' +
    'author_id bigint not null, ' +
    'prerelease boolean not null, ' +
    'created_at timestamp not null, ' +
    'published_at timestamp not null, ' +
    'body text, ' +
    'primary key(id, event_id)' +
    ')'
  )
  # variable
  c.exec('drop table if exists gha_releases_assets')
  c.exec(
    'create table gha_releases_assets(' +
    'release_id bigint not null, ' +
    'event_id bigint not null, ' +
    'asset_id bigint not null, ' +
    'primary key(release_id, event_id, asset_id)' +
    ')'
  )

  # gha_assets
  # Table details and analysis in `analysis/analysis.txt` and `analysis/asset_*.json`
  # Key: uploader_id
  # variable
  c.exec('drop table if exists gha_assets')
  c.exec(
    'create table gha_assets(' +
    'id bigint not null, ' +
    'event_id bigint not null, ' +
    'name varchar(200) not null, ' +
    'label varchar(120), ' +
    'uploader_id bigint not null, ' +
    'content_type varchar(80) not null, ' +
    'state varchar(20) not null, ' +
    'size int not null, ' +
    'download_count int not null, ' +
    'created_at timestamp not null, ' +
    'updated_at timestamp not null, ' +
    'primary key(id, event_id)' +
    ')'
  )

  # gha_pull_requests
  # Table details and analysis in `analysis/analysis.txt` and `analysis/pull_request_*.json`
  # Keys: actor: user_id, branch: base_sha, head_sha
  # Nullable keys: actor: merged_by_id, assignee_id, milestone: milestone_id
  # Arrays: actors: assignees, requested_reviewers
  # variable
  c.exec('drop table if exists gha_pull_requests')
  c.exec(
    'create table gha_pull_requests(' +
    'id bigint not null, ' +
    'event_id bigint not null, ' +
    'user_id bigint not null, ' +
    'base_sha varchar(40) not null, ' +
    'head_sha varchar(40) not null, ' +
    'merged_by_id bigint, ' +
    'assignee_id bigint, ' +
    'milestone_id bigint, ' +
    'number int not null, ' +
    'state varchar(20) not null, ' +
    'locked boolean not null, ' +
    'title text not null, ' +
    'body text, ' +
    'created_at timestamp not null, ' +
    'updated_at timestamp not null, ' +
    'closed_at timestamp, ' +
    'merged_at timestamp, ' +
    'merge_commit_sha varchar(40), ' +
    'merged boolean, ' +
    'mergeable boolean, ' +
    'rebaseable boolean, ' +
    'mergeable_state varchar(20), ' +
    'comments int, ' +
    'review_comments int, ' +
    'maintainer_can_modify boolean, ' +
    'commits int, ' +
    'additions int, ' +
    'deletions int, ' +
    'changed_files int, ' +
    'primary key(id, event_id)' +
    ')'
  )
  # variable
  c.exec('drop table if exists gha_pull_requests_assignees')
  c.exec(
    'create table gha_pull_requests_assignees(' +
    'pull_request_id bigint not null, ' +
    'event_id bigint not null, ' +
    'assignee_id bigint not null, ' +
    'primary key(pull_request_id, event_id, assignee_id)' +
    ')'
  )
  # variable
  c.exec('drop table if exists gha_pull_requests_requested_reviewers')
  c.exec(
    'create table gha_pull_requests_requested_reviewers(' +
    'pull_request_id bigint not null, ' +
    'event_id bigint not null, ' +
    'requested_reviewer_id bigint not null, ' +
    'primary key(pull_request_id, event_id, requested_reviewer_id)' +
    ')'
  )

  # gha_branches
  # Table details and analysis in `analysis/analysis.txt` and `analysis/branch_*.json`
  # Nullable keys: forkee: repo_id, actor: user_id
  # variable
  c.exec('drop table if exists gha_branches')
  c.exec(
    'create table gha_branches(' +
    'sha varchar(40) not null, ' +
    'event_id bigint not null, ' +
    'user_id bigint, ' +
    'repo_id bigint, ' +
    'label varchar(200) not null, ' +
    'ref varchar(200) not null, ' +
    'primary key(sha, event_id)' +
    ')'
  )
  # TODO: consider adding INDEXes, foreign keys are not needed - they slow down processing a lot.

rescue PG::Error => e
  puts e.message
  binding.pry
ensure
  c.close if c
  puts 'Done'
end

puts 'This program will recreate DB structure (dropping all existing data)'
print 'Continue? (y/n) '
c = mgetc
puts "\n"
structure if c == 'y'

