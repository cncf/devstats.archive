#!/usr/bin/env ruby

# rubocop:disable Style/GlobalVars
require 'pry'
require 'date'
require 'open-uri'
require 'zlib'
require 'stringio'
require 'json'
require 'etc'
require './conn' # All database details & setup there

$thr_n = Etc.nprocessors
puts "Available #{$thr_n} processors"

# Use environment variable to have singlethreaded version
$thr_n = 1 if ENV['GHA2DB_ST']

# All those variables can be set via environment variables
# Set $debug = 1 to see output for all events generated
# Set $debug = 2 to see database queries
# Set $json_out to save output JSON file
# Set $db_out = true if You want to put int PSQL DB
$debug = ENV['GHA2DB_DEBUG'] ? ENV['GHA2DB_DEBUG'].to_i : 0
$json_out = ENV['GHA2DB_JSON'] ? true : false
$db_out = ENV['GHA2DB_NODB'] ? false : true

# Truncate text to <= size bytes (note that this can be a lot less UTF-8 runes)
def trunc(str, size)
  len = str.bytesize
  return str if len < size
  r = ''
  i = 0
  while r.bytesize < size
    r += str[i]
    i += 1
  end
  r.bytesize <= size ? r : r[0..-2]
end

# Create prepared statement, bind args, execute and destroy statement
def exec_stmt(con, sid, stmt, args)
  args.each { |arg| arg.delete!("\000") if arg.is_a?(String) }
  p [sid, stmt, args] if $debug >= 2 || ENV['GHA2DB_QOUT']
  if $pg
    con.prepare sid, stmt
    con.exec_prepared(sid, args).tap do
      con.exec('deallocate ' + sid)
    end
  else
    pstmt = con.prepare stmt
    results = pstmt.execute(*args)
    ary = []
    results&.each { |row| ary << row }
    pstmt.close
    ary
  end
rescue => e
  puts 'Exception:'
  puts e.message
  p [sid, stmt, args]
  p $ev[Thread.current.object_id]
  p $dts
  raise e
end

def lookup_label(con, sid, name, color)
  r = exec_stmt(
    con,
    sid,
    "select id from gha_labels where name=#{n_value(1)} and color=#{n_value(2)}",
    [name, color]
  )
  r.count.positive? ? r.first['id'] : [name, color].hash
end

def gha_actor(con, sid, actor)
  # gha_actors
  # {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592,
  # "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
  # {"id"=>8, "login"=>34, "display_login"=>34, "gravatar_id"=>0, "url"=>63, "avatar_url"=>49}
  exec_stmt(
    con,
    sid,
    insert_ignore("into gha_actors(id, login) #{n_values(2)}"),
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
    'insert into gha_milestones('\
    'id, event_id, closed_at, closed_issues, created_at, creator_id, '\
    'description, due_on, number, open_issues, state, title, updated_at'\
    ') ' + n_values(13),
    [
      milestone['id'],
      eid,
      milestone['closed_at'] ? parse_timestamp(milestone['closed_at']) : nil,
      milestone['closed_issues'],
      parse_timestamp(milestone['created_at']),
      milestone['creator'] ? milestone['creator']['id'] : nil,
      milestone['description'] ? trunc(milestone['description'], 0xffff) : nil,
      milestone['due_on'] ? parse_timestamp(milestone['due_on']) : nil,
      milestone['number'],
      milestone['open_issues'],
      milestone['state'],
      trunc(milestone['title'], 200),
      parse_timestamp(milestone['updated_at'])
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
    'insert into gha_forkees('\
    'id, event_id, name, full_name, owner_id, description, fork, '\
    'created_at, updated_at, pushed_at, homepage, size, '\
    'stargazers_count, has_issues, has_projects, has_downloads, '\
    'has_wiki, has_pages, forks, default_branch, open_issues, '\
    'watchers, public) ' + n_values(23),
    [
      forkee['id'],
      eid,
      trunc(forkee['name'], 80),
      trunc(forkee['full_name'], 200),
      forkee['owner']['id'],
      forkee['description'] ? trunc(forkee['description'], 0xffff) : nil,
      forkee['fork'],
      parse_timestamp(forkee['created_at']),
      parse_timestamp(forkee['updated_at']),
      parse_timestamp(forkee['pushed_at']),
      forkee['homepage'],
      forkee['size'],
      forkee['stargazers_count'],
      forkee['has_issues'],
      forkee['has_projects'],
      forkee['has_downloads'],
      forkee['has_wiki'],
      forkee['has_pages'],
      forkee['forks'],
      trunc(forkee['default_branch'], 200),
      forkee['open_issues'],
      forkee['watchers'],
      forkee['public']
    ]
  )
end

def gha_branch(con, sid, eid, branch, skip_repo_id = nil)
  # user
  gha_actor(con, sid, branch['user']) if branch['user']

  # repo
  if branch['repo'] && (!skip_repo_id || branch['repo']['id'] != skip_repo_id)
    gha_forkee(con, sid, eid, branch['repo'])
  end

  # gha_branches
  exec_stmt(
    con,
    sid,
    'insert into gha_branches(sha, event_id, user_id, repo_id, label, ref) ' + n_values(6),
    [
      branch['sha'],
      eid,
      branch['user'] ? branch['user']['id'] : nil,
      branch['repo'] ? branch['repo']['id'] : nil,
      trunc(branch['label'], 200),
      trunc(branch['ref'], 200)
    ]
  )
end

# Write single event to PSQL
# rubocop:disable Metrics/BlockLength
def write_to_pg(con, ev)
  sid = $pg ? 'stmt' + Thread.current.object_id.to_s : ''
  # gha_events
  # {"id:String"=>48592, "type:String"=>48592, "actor:Hash"=>48592, "repo:Hash"=>48592,
  # "payload:Hash"=>48592, "public:TrueClass"=>48592, "created_at:String"=>48592,
  # "org:Hash"=>19451}
  # {"id"=>10, "type"=>29, "actor"=>278, "repo"=>290, "payload"=>216017, "public"=>4,
  # "created_at"=>20, "org"=>230}
  # Fields actor_login, repo_name are copied from (gha_actors and gha_repos) to save
  # joins on complex queries (MySQL has no hash joins and is very slow on big tables joins)
  event_id = ev['id']
  rs = exec_stmt(con, sid, 'select 1 from gha_events where id=' + n_value(1), [event_id])
  return 0 if rs.count.positive?
  exec_stmt(
    con,
    sid,
    'insert into gha_events('\
    'id, type, actor_id, repo_id, public, created_at, '\
    'org_id, actor_login, repo_name) ' + n_values(9),
    [
      event_id,
      ev['type'],
      ev['actor']['id'],
      ev['repo']['id'],
      ev['public'],
      parse_timestamp(ev['created_at']),
      ev['org'] ? ev['org']['id'] : nil,
      ev['actor']['login'],
      ev['repo']['name']
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
    insert_ignore("into gha_repos(id, name) #{n_values(2)}"),
    [repo['id'], repo['name']]
  )

  # gha_orgs
  # {"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494,
  # "url:String"=>18494, "avatar_url:String"=>18494}
  # {"id"=>8, "login"=>38, "gravatar_id"=>0, "url"=>66, "avatar_url"=>49}
  org = ev['org']
  if org
    exec_stmt(
      con,
      sid,
      insert_ignore("into gha_orgs(id, login) #{n_values(2)}"),
      [org['id'], org['login']]
    )
  end

  # gha_payloads
  # {"push_id:Fixnum"=>24636, "size:Fixnum"=>24636, "distinct_size:Fixnum"=>24636,
  # "ref:String"=>30522, "head:String"=>24636, "before:String"=>24636, "commits:Array"=>24636,
  # "action:String"=>14317, "issue:Hash"=>6446, "comment:Hash"=>6055, "ref_type:String"=>8010,
  # "master_branch:String"=>6724, "description:String"=>3701, "pusher_type:String"=>8010,
  # "pull_request:Hash"=>4475, "ref:NilClass"=>2124, "description:NilClass"=>3023,
  # "number:Fixnum"=>2992, "forkee:Hash"=>1211, "pages:Array"=>370, "release:Hash"=>156,
  # "member:Hash"=>219}
  # {"push_id"=>10, "size"=>4, "distinct_size"=>4, "ref"=>110, "head"=>40, "before"=>40,
  # "commits"=>33215, "action"=>9, "issue"=>87776, "comment"=>177917, "ref_type"=>10,
  # "master_branch"=>34, "description"=>3222, "pusher_type"=>4, "pull_request"=>70565,
  # "number"=>5, "forkee"=>6880, "pages"=>855, "release"=>31206, "member"=>1040}
  # 48746
  # using exec_stmt (without select), because payload are per event_id.
  pl = ev['payload']
  exec_stmt(
    con,
    sid,
    'insert into gha_payloads('\
    'event_id, push_id, size, ref, head, befor, action, '\
    'issue_id, comment_id, ref_type, master_branch, '\
    'description, number, forkee_id, release_id, member_id'\
    ') ' + n_values(16),
    [
      event_id,
      pl['push_id'],
      pl['size'],
      pl['ref'] ? trunc(pl['ref'], 200) : nil,
      pl['head'],
      pl['before'],
      pl['action'],
      pl['issue'] ? pl['issue']['id'] : nil,
      pl['comment'] ? pl['comment']['id'] : nil,
      pl['ref_type'],
      pl['master_branch'] ? trunc(pl['master_branch'], 200) : nil,
      pl['description'] ? trunc(pl['description'], 0xffff) : nil,
      pl['number'],
      pl['forkee'] ? pl['forkee']['id'] : nil,
      pl['release'] ? pl['release']['id'] : nil,
      pl['member'] ? pl['member']['id'] : nil
    ]
  )

  # gha_commits
  # {"sha:String"=>23265, "author:Hash"=>23265, "message:String"=>23265,
  # "distinct:TrueClass"=>21789, "url:String"=>23265, "distinct:FalseClass"=>1476}
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
      'insert into gha_commits('\
      'sha, event_id, author_name, message, is_distinct) ' + n_values(5),
      [
        sha,
        event_id,
        trunc(commit['author']['name'], 160),
        commit['message'] ? trunc(commit['message'], 0xffff) : nil,
        commit['distinct']
      ]
    )

    # event-commit connection
    exec_stmt(
      con,
      sid,
      'insert into gha_events_commits(event_id, sha) ' + n_values(2),
      [event_id, sha]
    )
  end

  # gha_pages
  # {"page_name:String"=>370, "title:String"=>370, "summary:NilClass"=>370,
  # "action:String"=>370, "sha:String"=>370, "html_url:String"=>370}
  # {"page_name"=>65, "title"=>65, "summary"=>0, "action"=>7, "sha"=>40, "html_url"=>130}
  # 370
  pages = pl['pages'] || []
  pages.each do |page|
    sha = page['sha']
    # page
    exec_stmt(
      con,
      sid,
      insert_ignore("into gha_pages(sha, event_id, action, title) #{n_values(4)}"),
      [
        sha,
        event_id,
        page['action'],
        trunc(page['title'], 300)
      ]
    )

    # event-page connection
    exec_stmt(
      con,
      sid,
      insert_ignore("into gha_events_pages(event_id, sha) #{n_values(2)}"),
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
      insert_ignore('into gha_comments('\
      'id, event_id, body, created_at, updated_at, type, user_id, '\
      'commit_id, original_commit_id, diff_hunk, position, '\
      'original_position, path, pull_request_review_id, line'\
      ') ' + n_values(15)),
      [
        cid,
        event_id,
        comment['body'] ? trunc(comment['body'], 0xffff) : nil,
        parse_timestamp(comment['created_at']),
        parse_timestamp(comment['updated_at']),
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
      'insert into gha_issues('\
      'id, event_id, assignee_id, body, closed_at, comments, created_at, '\
      'locked, milestone_id, number, state, title, updated_at, user_id, '\
      'is_pull_request) ' + n_values(15),
      [
        iid,
        event_id,
        issue['assignee'] ? issue['assignee']['id'] : nil,
        issue['body'] ? trunc(issue['body'], 0xffff) : nil,
        issue['closed_at'] ? parse_timestamp(issue['closed_at']) : nil,
        issue['comments'],
        parse_timestamp(issue['created_at']),
        issue['locked'],
        issue['milestone'] ? issue['milestone']['id'] : nil,
        issue['number'],
        issue['state'],
        issue['title'],
        parse_timestamp(issue['updated_at']),
        issue['user']['id'],
        issue['pull_request'] ? true : false
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
        'insert into gha_issues_assignees(issue_id, event_id, assignee_id) ' + n_values(3),
        [iid, event_id, aid]
      )
    end

    # labels
    labels = issue['labels']
    labels.each do |label|
      lid = label['id']
      lid = lookup_label(con, sid, trunc(label['name'], 160), label['color']) unless lid
      exec_stmt(
        con,
        sid,
        insert_ignore('into gha_labels(id, name, color, is_default) ' + n_values(4)),
        [
          lid,
          trunc(label['name'], 160),
          label['color'],
          label['default']
        ]
      )
      # issue-label connection
      exec_stmt(
        con,
        sid,
        insert_ignore("into gha_issues_labels(issue_id, event_id, label_id) #{n_values(3)}"),
        [iid, event_id, lid]
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
  1
end
# rubocop:enable Metrics/BlockLength

# Are we interested in this org/repo ?
def repo_hit(data, forg, frepo)
  unless data
    puts 'Broken repo name'
    return false
  end
  org, repo = *data.split('/')
  return false unless forg.length.zero? || forg.include?(org)
  return false unless frepo.length.zero? || frepo.include?(repo)
  true
end

# This is for debugging
$ev = {}
# Parse signe GHA JSON event
def parse_json(con, json, dt, forg, frepo)
  h = JSON.parse json
  f = 0
  e = 0
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
      e = write_to_pg(con, h)
      $ev.delete(Thread.current.object_id)
    end
    puts "Processed: '#{dt}' event: #{eid}" if $debug >= 1
    f = 1
  end
  [f, e]
end

$dts = {} # Debug which dates are parsing at the moment of eventual exception
# This is a work for single thread - 1 hour of GHA data
# Usually such JSON conatin about 15000 - 60000 singe GHA events
def get_gha_json(dt, forg, frepo)
  con = conn
  fn = dt.strftime('http://data.githubarchive.org/%Y-%m-%d-%k.json.gz').sub(' ', '')
  puts "Working on: #{fn}"
  n = f = e = 0
  $dts[Thread.current.object_id] = dt
  open(fn, 'rb') do |json_tmp_file|
    puts "Opened: #{fn}"
    jsons = Zlib::GzipReader.new(json_tmp_file).read
    puts "Decompressed: #{fn}"
    jsons = jsons.split("\n")
    puts "Splitted: #{fn}"
    jsons.each do |json|
      r = parse_json(con, json, dt, forg, frepo)
      n += 1
      f += r[0]
      e += r[1]
    end
  end
  $dts.delete(Thread.current.object_id)
  puts "Parsed: #{fn}: #{n} JSONs, found #{f} matching, events #{e}"
rescue OpenURI::HTTPError => e
  puts "No data yet for #{dt}"
rescue Zlib::GzipFile::Error, Zlib::DataError => e
  puts 'Gzip decompression exception:'
  puts e.message
  p "Date: #{dt}"
rescue => e
  puts 'General exception:'
  puts e.message
  p "Date: #{dt}"
  p $dts
  raise e
ensure
  con&.close
end

# Main work horse
def gha2db(args)
  d_from = DateTime.strptime(
    "#{args[0]} #{args[1]}:00:00+00:00",
    '%Y-%m-%d %H:%M:%S%z'
  ).to_time.utc
  d_to = DateTime.strptime(
    "#{args[2]} #{args[3]}:00:00+00:00",
    '%Y-%m-%d %H:%M:%S%z'
  ).to_time.utc
  org = (args[4] || '').split(',').map(&:strip)
  repo = (args[5] || '').split(',').map(&:strip)
  puts "Running: #{d_from} - #{d_to} #{org.join('+')}/#{repo.join('+')}"
  dt = d_from
  if $thr_n > 1
    thr_pool = []
    while dt <= d_to
      thr = Thread.new(dt) { |adt| get_gha_json(adt, org, repo) }
      thr_pool << thr
      dt += 3600
      # rubocop:disable Style/Next
      if thr_pool.length == $thr_n
        thr = thr_pool.first
        thr.join
        thr_pool = thr_pool[1..-1]
      end
      # rubocop:enable Style/Next
    end
    puts 'Final threads join'
    thr_pool.each(&:join)
  else
    puts 'Using single threaded version'
    while dt <= d_to
      get_gha_json(dt, org, repo)
      dt += 3600
    end
  end
  puts 'All done.'
end

# Required args
if ARGV.length < 4
  puts 'Arguments required: date_from_YYYY-MM-DD hour_from_HH date_to_YYYY-MM-DD hour_to_HH '\
  '[\'org1,org2,...,orgN\' [\'repo1,repo2,...,repoN\']]'
  exit 1
end

gha2db(ARGV)

# rubocop:enable Style/GlobalVars
