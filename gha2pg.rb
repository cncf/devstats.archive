#!/usr/bin/env ruby

require 'pry'
require 'date'
require 'open-uri'
require 'zlib'
require 'stringio'
require 'json'
require 'etc'
require 'pg'

$thr_n = Etc.nprocessors
puts "Available #{$thr_n} processors"
$thr_n = 1 if ENV['GHA2PG_ST']

# Set $debug = 1 to see output for all events generated
# Set $debug = 2 to see database queries
# Set $json_out to save output JSON file
# Set $db_out = true if You want to put int PSQL DB
$debug = 0
$json_out = false
$db_out = true

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
def connect_db
  PG::Connection.new(
    host: ENV['PG_HOST'] || 'localhost',
    port: (ENV['PG_PORT'] || '5432').to_i,
    dbname: ENV['PG_DB'] || 'gha',
    user: ENV['PG_USER'] || 'gha_admin',
    password: ENV['PG_PASS'] || 'password'
  )
rescue PG::Error => e
  puts e.message
  exit(1)
end

# returns for n:
# n=1 -> values($1)
# n=10 -> values($1, $2, $3, .., $10)
def n_values(n)
  s = 'values('
  (1..n).each { |i| s += "$#{i}, " }
  s[0..-3] + ')'
end

# Create prepared statement, bind args, execute and destroy statement
def exec_stmt(con, sid, stmt, args)
  args.each { |arg| arg = arg.gsub!("\000", '') if arg.is_a?(String) }
  p [sid, stmt, args] if $debug >= 2
  con.prepare sid, stmt
  con.exec_prepared(sid, args).tap do
    con.exec('deallocate ' + sid)
  end
rescue Exception => e
  puts "Exception:"
  puts e.message
  p [sid, stmt, args]
  p $ev[Thread.current.object_id]
  raise e
end

def lookup_label(con, sid, name, color)
  r = exec_stmt(
    con,
    sid,
    'select id from gha_labels where name=$1 and color=$2',
    [name, color]
  )
  r.count > 0 ? r.first['id'] : [name, color].hash
end

def gha_actor(con, sid, actor)
  # gha_actors
  # {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592, "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
  # {"id"=>8, "login"=>34, "display_login"=>34, "gravatar_id"=>0, "url"=>63, "avatar_url"=>49}
  exec_stmt(
    con,
    sid,
    'insert into gha_actors(id, login) values($1, $2) on conflict do nothing',
    [actor['id'], actor['login']]
  )
end

def gha_milestone(con, sid, eid, milestone)
  # creator
  gha_actor(con, sid, milestone['creator']) if milestone['creator']

  # gha_milestones
  exec_stmt(
    con,
    sid,
    'insert into gha_milestones(' +
    'id, event_id, closed_at, closed_issues, created_at, creator_id, ' +
    'description, due_on, number, open_issues, state, title, updated_at' +
    ') ' + n_values(13),
    [
      milestone['id'],
      eid,
      milestone['closed_at'] ? Time.parse(milestone['closed_at']) : nil,
      milestone['closed_issues'],
      Time.parse(milestone['created_at']),
      milestone['creator'] ? milestone['creator']['id']: nil,
      milestone['description'],
      milestone['due_on'] ? Time.parse(milestone['due_on']) : nil,
      milestone['number'],
      milestone['open_issues'],
      milestone['state'],
      milestone['title'][0..199],
      Time.parse(milestone['updated_at'])
    ]
  )
end

def gha_forkee(con, sid, eid, forkee)
  # owner
  gha_actor(con, sid, forkee['owner'])

  # gha_forkees
  # Table details and analysis in `analysis/analysis.txt` and `analysis/forkee_*.json`
  exec_stmt(
    con,
    sid,
    'insert into gha_forkees(' +
    'id, event_id, name, full_name, owner_id, description, fork, ' +
    'created_at, updated_at, pushed_at, homepage, size, ' +
    'stargazers_count, has_issues, has_projects, has_downloads, ' +
    'has_wiki, has_pages, forks, default_branch, open_issues, ' +
    'watchers, public) ' + n_values(23),
    [
      forkee['id'],
      eid,
      forkee['name'][0..79],
      forkee['full_name'][0..199],
      forkee['owner']['id'],
      forkee['description'],
      forkee['fork'],
      Time.parse(forkee['created_at']),
      Time.parse(forkee['updated_at']),
      Time.parse(forkee['pushed_at']),
      forkee['homepage'],
      forkee['size'],
      forkee['stargazers_count'],
      forkee['has_issues'],
      forkee['has_projects'],
      forkee['has_downloads'],
      forkee['has_wiki'],
      forkee['has_pages'],
      forkee['forks'],
      forkee['default_branch'][0..199],
      forkee['open_issues'],
      forkee['watchers'],
      forkee['public']
    ]
  )
end

def gha_branch(con, sid, eid, branch, skip_repo_id=nil)
  # user
  gha_actor(con, sid, branch['user']) if branch['user']

  # repo
  if branch['repo']
    gha_forkee(con, sid, eid, branch['repo']) unless skip_repo_id && branch['repo']['id'] == skip_repo_id
  end

  # gha_branches
  exec_stmt(
    con,
    sid,
    'insert into gha_branches(sha, event_id, user_id, repo_id, label, ref) ' + n_values(6),
    [
      branch['sha'],
      eid,
      branch['user']['id'],
      branch['repo'] ? branch['repo']['id'] : nil,
      branch['label'][0..199],
      branch['ref'][0..199]
    ]
  )
end

# Write single event to PSQL
def write_to_pg(con, ev)
  sid = 'stmt' + Thread.current.object_id.to_s
  # gha_events
  # {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592, "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592, "org:Hash"=>19451}
  # {"id"=>10, "type"=>29, "actor"=>278, "repo"=>290, "payload"=>216017, "public"=>4, "created_at"=>20, "org"=>230}
  event_id = ev['id']
  rs = exec_stmt(con, sid, 'select 1 from gha_events where id=$1', [event_id])
  return if rs.count > 0
  exec_stmt(
    con,
    sid,
    'insert into gha_events(id, type, actor_id, repo_id, public, created_at, org_id) ' +
    'values($1, $2, $3, $4, $5, $6, $7)',
    [
      event_id,
      ev['type'],
      ev['actor']['id'],
      ev['repo']['id'],
      ev['public'],
      Time.parse(ev['created_at']),
      ev['org'] ? ev['org']['id'] : nil
    ]
  )

  # gha_actors
  gha_actor(con, sid, ev['actor'])

  # gha_repos
  # {"id:Fixnum"=>48592, "name:String"=>48592, "url:String"=>48592}
  # {"id"=>8, "name"=>111, "url"=>140}
  repo = ev['repo']
  exec_stmt(
    con,
    sid,
    'insert into gha_repos(id, name) values($1, $2) on conflict do nothing',
    [repo['id'], repo['name']]
  )

  # gha_orgs
  # {"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494, "url:String"=>18494, "avatar_url:String"=>18494}
  # {"id"=>8, "login"=>38, "gravatar_id"=>0, "url"=>66, "avatar_url"=>49}
  org = ev['org']
  if org
    exec_stmt(
      con,
      sid,
      'insert into gha_orgs(id, login) values($1, $2) on conflict do nothing',
      [org['id'], org['login']]
    )
  end

  # gha_payloads
  # {"push_id:Fixnum"=>24636, "size:Fixnum"=>24636, "distinct_size:Fixnum"=>24636, "ref:String"=>30522, "head:String"=>24636, "before:String"=>24636, "commits:Array"=>24636, "action:String"=>14317, "issue:Hash"=>6446, "comment:Hash"=>6055, "ref_type:String"=>8010, "master_branch:String"=>6724, "description:String"=>3701, "pusher_type:String"=>8010, "pull_request:Hash"=>4475, "ref:NilClass"=>2124, "description:NilClass"=>3023, "number:Fixnum"=>2992, "forkee:Hash"=>1211, "pages:Array"=>370, "release:Hash"=>156, "member:Hash"=>219}
  # {"push_id"=>10, "size"=>4, "distinct_size"=>4, "ref"=>110, "head"=>40, "before"=>40, "commits"=>33215, "action"=>9, "issue"=>87776, "comment"=>177917, "ref_type"=>10, "master_branch"=>34, "description"=>3222, "pusher_type"=>4, "pull_request"=>70565, "number"=>5, "forkee"=>6880, "pages"=>855, "release"=>31206, "member"=>1040}
  # 48746
  # using exec_stmt (without select), because payload are per event_id.
  pl = ev['payload']
  exec_stmt(
    con,
    sid,
    'insert into gha_payloads(' +
    'event_id, push_id, size, ref, head, before, action, ' +
    'issue_id, comment_id, ref_type, master_branch, ' +
    'description, number, forkee_id, release_id, member_id' +
    ') ' + n_values(16),
    [
      event_id,
      pl['push_id'],
      pl['size'],
      pl['ref'] ? pl['ref'][0..199] : nil,
      pl['head'],
      pl['before'],
      pl['action'],
      pl['issue'] ? pl['issue']['id'] : nil,
      pl['comment'] ? pl['comment']['id'] : nil,
      pl['ref_type'],
      pl['master_branch'] ? pl['master_branch'][0..199] : nil,
      pl['description'],
      pl['number'],
      pl['forkee'] ? pl['forkee']['id'] : nil,
      pl['release'] ? pl['release']['id'] : nil,
      pl['member'] ? pl['member']['id'] : nil
    ]
  )

  # gha_commits
  # {"sha:String"=>23265, "author:Hash"=>23265, "message:String"=>23265, "distinct:TrueClass"=>21789, "url:String"=>23265, "distinct:FalseClass"=>1476}
  # {"sha"=>40, "author"=>177, "message"=>19005, "distinct"=>5, "url"=>191}
  # author: {"name:String"=>23265, "email:String"=>23265} (only git username/email)
  # author: {"name"=>96, "email"=>95}
  # 23265
  commits = pl['commits'] || []
  commits.each do |commit|
    sha = commit['sha']
    exec_stmt(
      con,
      sid,
        'insert into gha_commits(' +
        'sha, event_id, author_name, message, is_distinct) ' +
        'values($1, $2, $3, $4, $5)',
      [
        sha,
        event_id,
        commit['author']['name'][0..159],
        commit['message'],
        commit['distinct']
      ]
    )

    # event-commit connection
    exec_stmt(
      con,
      sid,
      'insert into gha_events_commits(event_id, sha) values($1, $2)',
      [event_id, sha]
    )
  end

  # gha_pages
  # {"page_name:String"=>370, "title:String"=>370, "summary:NilClass"=>370, "action:String"=>370, "sha:String"=>370, "html_url:String"=>370}
  # {"page_name"=>65, "title"=>65, "summary"=>0, "action"=>7, "sha"=>40, "html_url"=>130}
  # 370
  pages = pl['pages'] || []
  pages.each do |page|
    sha = page['sha']
    # page
    exec_stmt(
      con,
      sid,
        'insert into gha_pages(sha, event_id, action, title) values($1, $2, $3, $4) on conflict do nothing',
      [
        sha,
        event_id,
        page['action'],
        page['title'][0..299]
      ]
    )

    # event-page connection
    exec_stmt(
      con,
      sid,
      'insert into gha_events_pages(event_id, sha) values($1, $2) on conflict do nothing',
      [event_id, sha]
    )
  end

  # member
  member = pl['member']
  gha_actor(con, sid, member) if member

  # gha_comments
  # Table details and analysis in `analysis/analysis.txt` and `analysis/comment_*.json`
  comment = pl['comment']
  if comment
    # user
    gha_actor(con, sid, comment['user'])

    # comment
    cid = comment['id']
    exec_stmt(
      con,
      sid,
      'insert into gha_comments(' +
      'id, body, created_at, updated_at, type, user_id, ' +
      'commit_id, original_commit_id, diff_hunk, position, ' +
      'original_position, path, pull_request_review_id, line' +
      ') ' + n_values(14),
      [
        cid,
        comment['body'],
        Time.parse(comment['created_at']),
        Time.parse(comment['updated_at']),
        ev['type'],
        comment['user']['id'],
        comment['commit_id'],
        comment['original_commit_id'],
        comment['diff_hunk'],
        comment['position'],
        comment['original_position'],
        comment['path'],
        comment['pull_request_review_id'],
        comment['line']
      ]
    )
  end

  # gha_issues
  # Table details and analysis in `analysis/analysis.txt` and `analysis/issue_*.json`
  issue = pl['issue']
  if issue
    # user, assignee
    gha_actor(con, sid, issue['user'])
    gha_actor(con, sid, issue['assignee']) if issue['assignee']

    # issue
    iid = issue['id']
    exec_stmt(
      con,
      sid,
      'insert into gha_issues(' +
      'id, event_id, assignee_id, body, closed_at, comments, created_at, ' +
      'locked, milestone_id, number, state, title, updated_at, user_id' +
      ') ' + n_values(14),
      [
        iid,
        event_id,
        issue['assignee'] ? issue['assignee']['id'] : nil,
        issue['body'],
        issue['closed_at'] ? Time.parse(issue['closed_at']) : nil,
        issue['comments'],
        Time.parse(issue['created_at']),
        issue['locked'],
        issue['milestone'] ? issue['milestone']['id'] : nil,
        issue['number'],
        issue['state'],
        issue['title'],
        Time.parse(issue['updated_at']),
        issue['user']['id']
      ]
    )

    # milestone
    gha_milestone(con, sid, event_id, issue['milestone']) if issue['milestone']

    # assignees
    assignees = issue['assignees'] || []
    p_aid = issue['assignee'] ? issue['assignee']['id'] : nil
    assignees.each do |assignee|
      aid = assignee['id']
      next if aid == p_aid

      # assignee
      gha_actor(con, sid, assignee)

      # issue-assignee connection
      exec_stmt(
        con,
        sid,
        'insert into gha_issues_assignees(issue_id, event_id, assignee_id) values($1, $2, $3)',
        [iid, event_id, aid],
      )
    end

    # labels
    labels = issue['labels']
    labels.each do |label|
      lid = label['id']
      lid = lookup_label(con, sid, label['name'][0..159], label['color']) unless lid
      exec_stmt(
        con,
        sid,
        'insert into gha_labels(id, name, color, is_default) ' +
        'values($1, $2, $3, $4) on conflict do nothing',
        [
          lid,
          label['name'][0..159],
          label['color'],
          label['default']
        ]
      )
      # issue-label connection
      exec_stmt(
        con,
        sid,
        'insert into gha_issues_labels(issue_id, event_id, label_id) values($1, $2, $3) on conflict do nothing',
        [iid, event_id, lid],
      )
    end
  end

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
      'insert into gha_releases(' +
      'id, event_id, tag_name, target_commitish, name, draft, ' +
      'author_id, prerelease, created_at, published_at, body' +
      ') ' + n_values(11),
      [
        rid,
        event_id,
        release['tag_name'][0..199],
        release['target_commitish'][0..199],
        release['name'] ? release['name'][0..199] : nil,
        release['draft'],
        release['author']['id'],
        release['prerelease'],
        Time.parse(release['created_at']),
        Time.parse(release['published_at']),
        release['body']
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
        'insert into gha_assets(' +
        'id, event_id, name, label, uploader_id, content_type, ' +
        'state, size, download_count, created_at, updated_at' +
        ') ' + n_values(11),
          [
          aid,
          event_id,
          asset['name'][0..199],
          asset['label'] ? asset['label'][0..119] : nil,
          asset['uploader']['id'],
          asset['content_type'],
          asset['state'],
          asset['size'],
          asset['download_count'],
          Time.parse(asset['created_at']),
          Time.parse(asset['updated_at'])
        ]
      )

      # release-asset connection
      exec_stmt(
        con,
        sid,
        'insert into gha_releases_assets(release_id, event_id, asset_id) values($1, $2, $3)',
        [rid, event_id, aid],
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
      'insert into gha_pull_requests(' +
      'id, event_id, user_id, base_sha, head_sha, merged_by_id, assignee_id, milestone_id, ' +
      'number, state, locked, title, body, created_at, updated_at, closed_at, merged_at, ' +
      'merge_commit_sha, merged, mergeable, rebaseable, mergeable_state, comments, ' +
      'review_comments, maintainer_can_modify, commits, additions, deletions, changed_files' +
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
        pr['body'],
        Time.parse(pr['created_at']),
        Time.parse(pr['updated_at']),
        pr['closed_at'] ? Time.parse(pr['closed_at']) : nil,
        pr['merged_at'] ? Time.parse(pr['merged_at']) : nil,
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
        'insert into gha_pull_requests_assignees(pull_request_id, event_id, assignee_id) values($1, $2, $3)',
        [prid, event_id, aid],
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
        'insert into gha_pull_requests_requested_reviewers(pull_request_id, event_id, requested_reviewer_id) values($1, $2, $3)',
        [prid, event_id, reviewer['id']],
      )
    end
  end
end

# Are we interested in this org/repo ?
def repo_hit(data, forg, frepo)
  unless data
    puts "Broken repo name"
    return false
  end
  org, repo = *data.split('/')
  return false unless forg.length == 0 || forg.include?(org)
  return false unless frepo.length == 0 || frepo.include?(repo)
  true
end

$ev = {}  # This is for debugging
# Parse signe GHA JSON event
def threaded_parse(con, json, dt, forg, frepo)
  h = JSON.parse json
  f = 0
  full_name = h['repo']['name']
  if repo_hit(full_name, forg, frepo)
    eid = h['id']
    if $json_out
      prt = JSON.pretty_generate(h)
      ofn = "jsons/#{dt.to_i}_#{eid}.json"
      File.write ofn, prt
    end
    if $db_out
      $ev[Thread.current.object_id] = h
      write_to_pg(con, h)
      $ev.delete(Thread.current.object_id)
    end
    puts "Processed: '#{dt}' event: #{eid}" if $debug >= 1
    f = 1
  end
  return f
end

# This is a work for single thread - 1 hour of GHA data
# Usually such JSON conatin about 15000 - 60000 singe GHA events
def get_gha_json(dt, forg, frepo)
  con = connect_db
  fn = dt.strftime('http://data.githubarchive.org/%Y-%m-%d-%k.json.gz').sub(' ', '')
  puts "Working on: #{fn}"
  n = f = 0
  open(fn, 'rb') do |json_tmp_file|
    puts "Opened: #{fn}"
    jsons = Zlib::GzipReader.new(json_tmp_file).read
    puts "Decompressed: #{fn}"
    jsons = jsons.split("\n")
    puts "Splitted: #{fn}"
    jsons.each do |json|
      n += 1
      f += threaded_parse(con, json, dt, forg, frepo)
    end
  end
  puts "Parsed: #{fn}: #{n} JSONs, found #{f} matching"
rescue OpenURI::HTTPError => e
  puts "No data yet for #{dt}"
rescue Zlib::GzipFile::Error => e
  puts "Gzip decompression exception:"
  puts e.message
  p "Date: #{dt}"
rescue Exception => e
  puts "General exception:"
  puts e.message
  p "Date: #{dt}"
  raise e
ensure
  con.close if con
end

# Main work horse
def gha2pg(args)
  d_from = parsed_time = DateTime.strptime("#{args[0]} #{args[1]}:00:00+00:00", '%Y-%m-%d %H:%M:%S%z').to_time
  d_to = parsed_time = DateTime.strptime("#{args[2]} #{args[3]}:00:00+00:00", '%Y-%m-%d %H:%M:%S%z').to_time
  org = (args[4] || '').split(',').map(&:strip)
  repo = (args[5] || '').split(',').map(&:strip)
  puts "Running: #{d_from} - #{d_to} #{org.join('+')}/#{repo.join('+')}"
  dt = d_from
  if $thr_n > 1
    thr_pool = []
    while dt <= d_to
      thr = Thread.new(dt) { |adt| get_gha_json(adt, org, repo) }
      thr_pool << thr
      dt = dt + 3600
      if thr_pool.length == $thr_n
        thr = thr_pool.first
        thr.join
        thr_pool = thr_pool[1..-1]
      end
    end
    puts "Final threads join"
    thr_pool.each { |thr| thr.join }
  else
    puts "Using single threaded version"
    while dt <= d_to
      get_gha_json(dt, org, repo)
      dt = dt + 3600
    end
  end
  puts "All done."
end

# Required args
if ARGV.length < 4
  puts "Arguments required: date_from_YYYY-MM-DD hour_from_HH date_to_YYYY-MM-DD hour_to_HH ['org1,org2,...,orgN' ['repo1,repo2,...,repoN']]"
  exit 1
end

gha2pg(ARGV)
