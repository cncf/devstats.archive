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
  c.exec('drop table if exists gha_events')
  c.exec(
    'create table gha_events(' +
    'id bigint not null primary key, ' +
    'type varchar(40) not null, ' +
    'actor_id bigint not null, ' +
    'repo_id bigint not null, ' +
    'payload_id bigint not null, ' +
    'public boolean not null, ' +
    'created_at timestamp not null, ' +
    'org_id bigint' +
    ')'
  )
  # gha_actors
  # {"id:Fixnum"=>48592, "login:String"=>48592, "display_login:String"=>48592, "gravatar_id:String"=>48592, "url:String"=>48592, "avatar_url:String"=>48592}
  # {"id"=>8, "login"=>34, "display_login"=>34, "gravatar_id"=>0, "url"=>63, "avatar_url"=>49}
  c.exec('drop table if exists gha_actors')
  c.exec(
    'create table gha_actors(' +
    'id bigint not null primary key, ' +
    'login varchar(80) not null' +
    ')'
  )
  # gha_repos
  # {"id:Fixnum"=>48592, "name:String"=>48592, "url:String"=>48592}
  # {"id"=>8, "name"=>111, "url"=>140}
  c.exec('drop table if exists gha_repos')
  c.exec(
    'create table gha_repos(' +
    'id bigint not null primary key, ' +
    'name varchar(160) not null' +
    ')'
  )

  # gha_orgs
  #{"id:Fixnum"=>18494, "login:String"=>18494, "gravatar_id:String"=>18494, "url:String"=>18494, "avatar_url:String"=>18494}
  #{"id"=>8, "login"=>38, "gravatar_id"=>0, "url"=>66, "avatar_url"=>49}
  c.exec('drop table if exists gha_orgs')
  c.exec(
    'create table gha_orgs(' +
    'id bigint not null primary key, ' +
    'login varchar(80) not null' +
    ')'
  )

  # gha_payloads
  # {"push_id:Fixnum"=>24636, "size:Fixnum"=>24636, "distinct_size:Fixnum"=>24636, "ref:String"=>30522, "head:String"=>24636, "before:String"=>24636, "commits:Array"=>24636, "action:String"=>14317, "issue:Hash"=>6446, "comment:Hash"=>6055, "ref_type:String"=>8010, "master_branch:String"=>6724, "description:String"=>3701, "pusher_type:String"=>8010, "pull_request:Hash"=>4475, "ref:NilClass"=>2124, "description:NilClass"=>3023, "number:Fixnum"=>2992, "forkee:Hash"=>1211, "pages:Array"=>370, "release:Hash"=>156, "member:Hash"=>219}
  # {"push_id"=>10, "size"=>4, "distinct_size"=>4, "ref"=>110, "head"=>40, "before"=>40, "commits"=>33215, "action"=>9, "issue"=>87776, "comment"=>177917, "ref_type"=>10, "master_branch"=>34, "description"=>3222, "pusher_type"=>4, "pull_request"=>70565, "number"=>5, "forkee"=>6880, "pages"=>855, "release"=>31206, "member"=>1040}
  # 48746
  c.exec('drop table if exists gha_payloads')
  c.exec(
    'create table gha_payloads(' +
    'id bigint not null primary key, ' +
    'push_id int, ' +
    'size int, ' +
    'ref varchar(160), ' +
    'head varchar(40), ' +
    'before varchar(40), ' +
    'action varchar(20), ' +
    'issue_id bigint, ' +
    'comment_id bigint, ' +
    'ref_type varchar(20), ' +
    'master_branch varchar(160), ' +
    'description text, ' +
    'number int, ' +
    'forkee_id bigint, ' +
    'release_id bigint, ' +
    'member_id bigint' +
    ')'
  )
  # special handle (commits, pages)

  # gha_commits
  # {"sha:String"=>23265, "author:Hash"=>23265, "message:String"=>23265, "distinct:TrueClass"=>21789, "url:String"=>23265, "distinct:FalseClass"=>1476}
  # {"sha"=>40, "author"=>177, "message"=>19005, "distinct"=>5, "url"=>191}
  # author: {"name:String"=>23265, "email:String"=>23265} (only git username/email)
  # author: {"name"=>96, "email"=>95}
  # 23265
  c.exec('drop table if exists gha_commits')
  c.exec(
    'create table gha_commits(' +
    'sha varchar(40) not null primary key, ' +
    'author_name varchar(160) not null, ' +
    'author_email varchar(160) not null, ' +
    'message text not null, ' +
    'is_distinct boolean not null' +
    ')'
  )
  c.exec('drop table if exists gha_payloads_commits')
  c.exec(
    'create table gha_payloads_commits(' +
    'payload_id bigint not null, ' +
    'sha varchar(40) not null, ' +
    'primary key(payload_id, sha)' +
    ')'
  )

  # gha_pages
  # {"page_name:String"=>370, "title:String"=>370, "summary:NilClass"=>370, "action:String"=>370, "sha:String"=>370, "html_url:String"=>370}
  # {"page_name"=>65, "title"=>65, "summary"=>0, "action"=>7, "sha"=>40, "html_url"=>130}
  # 370
  c.exec('drop table if exists gha_pages')
  c.exec(
    'create table gha_pages(' +
    'sha varchar(40) not null primary key, ' +
    'action varchar(20) not null, ' +
    'page_name varchar(160) not null, ' +
    'title varchar(160) not null' +
    ')'
  )
  c.exec('drop table if exists gha_payloads_pages')
  c.exec(
    'create table gha_payloads_pages(' +
    'payload_id bigint not null, ' +
    'sha varchar(40) not null, ' +
    'primary key(payload_id, sha)' +
    ')'
  )


  # FIXME: remember to add foreign keys !
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

