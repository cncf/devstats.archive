#!/usr/bin/env ruby

require 'pry'
require './time_stuff'
require './conn' # All database details & setup there

def sync(args)
  org = (args[0] || '').split(',').map(&:strip)
  repo = (args[1] || '').split(',').map(&:strip)
  puts "Running on: #{org.join('+')}/#{repo.join('+')}"

  # Connect to database
  con = conn

  # Get max date from gha_events
  r = exec_sql(
    con,
    'select max(created_at) as max_created_at ' +
    'from gha_events'
  )
  max_dt = $pg ? "'now'" : 'now()'
  max_dt = "'#{r.first['max_created_at']}'" if r.first['max_created_at']

  # Create date range
  from = Time.parse(max_dt) + 300
  to = Time.now
  from_date = from.strftime('%Y-%m-%d')
  from_hour = from.hour.to_s
  to_date = to.strftime('%Y-%m-%d')
  to_hour = to.hour.to_s

  # Get new GHAs
  puts "Range: #{from_date} #{from_hour} - #{to_date} #{to_hour}"
  cmd = "./gha2db.rb #{from_date} #{from_hour} #{to_date} #{to_hour} #{org.join(',')} #{repo.join(',')}"
  puts cmd
  res = system cmd
  unless res
    puts "Command failed: '#{cmd}'"
    exit 1
  end

  # Recompute views and DB summaries
  cmd = './structure.rb'
  puts cmd
  res = system(
    {'GHA2DB_SKIPTABLE' => '1', 'GHA2DB_MGETC' => 'y'},
    cmd
  )
  unless res
    puts "Command failed: '#{cmd}'"
    exit 1
  end

  # DB2Influx
  metrics_dir = $pg ? 'psql_metrics' : 'mysql_metrics'

  # Reviewers daily, weekly, monthly, yearly
  %w(d w m y).each do |period|
    cmd = "./db2influx.rb reviewers_#{period} psql_metrics/reviewers.sql '#{to_ymd(from)}' '#{to_ymd(to)}' #{period}"
    puts cmd
    res = system cmd
    unless res
      puts "Command failed: '#{cmd}'"
      exit 1
    end
  end

  puts "Sync success"
end

sync(ARGV)
