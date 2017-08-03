#!/usr/bin/env ruby

require 'pg'
require 'pry'

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

# By default we're not refreshing materialized view before doing query
# You can do it by setting GHA2PG_REFRESH environment variable
# Materialized index holds all texts used in commits, comments, PRs, issues
# Refreshing materialized view is needed if You changes database data since last run.
$refresh = ENV['GHA2PG_REFRESH'] ? true : false

def runq(sql_file)
  # Connect to database
  c = PG::Connection.new(
    host: ENV['PG_HOST'] || 'localhost',
    port: (ENV['PG_PORT'] || '5432').to_i,
    dbname: ENV['PG_DB'] || 'gha',
    user: ENV['PG_USER'] || 'gha_admin',
    password: ENV['PG_PASS'] || 'password'
  )
  sql = File.read(sql_file)
  c.exec('refresh materialized view gha_view_texts') if $refresh
  res = c.exec(sql)
  return unless res.count > 0
  hdr = res.first.keys
  hdrl = {}
  hdr.each do |k|
    hdrl[k] = (res.map { |r| (r[k] || '').to_s } + [k]).max_by(&:length).length
  end

  s = '/'
  hdr.each do |k|
    fmt = "%-#{hdrl[k]}s"
    v = '-' * hdrl[k]
    s += "#{fmt % v}+"
  end
  s = s[0..-2] + "\\\n"
  puts s

  s = '|'
  hdr.each do |k|
    fmt = "%-#{hdrl[k]}s"
    s += "#{fmt % k}|"
  end
  s += "\n"
  puts s

  s = '+'
  hdr.each do |k|
    fmt = "%-#{hdrl[k]}s"
    v = '-' * hdrl[k]
    s += "#{fmt % v}+"
  end
  s = s[0..-2] + "+\n"
  puts s

  res.each do |r|
    s = '|'
    r.each do |k, v|
      fmt = "%-#{hdrl[k]}s"
      s += "#{fmt % v}|"
    end
    s = s[0..-2] + "|\n"
    puts s
  end

  s = '\\'
  hdr.each do |k|
    fmt = "%-#{hdrl[k]}s"
    v = '-' * hdrl[k]
    s += "#{fmt % v}+"
  end
  s = s[0..-2] + "/\n"
  puts s

rescue PG::Error => e
  puts e.message
  binding.pry
ensure
  c.close if c
end

if ARGV.count < 1
  puts "Required SQL file name"
  exit 1
end

runq(ARGV.first)

