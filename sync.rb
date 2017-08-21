#!/usr/bin/env ruby

# rubocop:disable Style/GlobalVars
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
    'select max(created_at) as max_created_at '\
    'from gha_events'
  )
  max_dt = $pg ? "'now'" : 'now()'
  max_dt = "'#{r.first['max_created_at']}'" if r.first['max_created_at']

  # Create date range
  # Just to get into next GHA hour
  from = Time.parse(max_dt).utc + 300
  to = Time.now.utc
  from_date = from.strftime('%Y-%m-%d')
  from_hour = from.hour.to_s
  to_date = to.strftime('%Y-%m-%d')
  to_hour = to.hour.to_s

  # Get new GHAs
  puts "Range: #{from_date} #{from_hour} - #{to_date} #{to_hour}"
  cmd = "./gha2db.rb #{from_date} #{from_hour} #{to_date} "\
        "#{to_hour} #{org.join(',')} #{repo.join(',')}"
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
    { 'GHA2DB_SKIPTABLE' => '1', 'GHA2DB_MGETC' => 'y' },
    cmd
  )
  unless res
    puts "Command failed: '#{cmd}'"
    exit 1
  end

  # DB2Influx
  unless ENV['GHA2DB_SKIPIDB']
    metrics_dir = $pg ? 'psql_metrics' : 'mysql_metrics'
    from = Time.parse('2015-08-01').utc if ENV['GHA2DB_RESETIDB']

    # Reviewers daily, weekly, monthly, quarterly, yearly
    %w[d w m q y].each do |period|
      cmd = "./db2influx.rb reviewers_#{period} #{metrics_dir}/reviewers.sql "\
            "'#{to_ymd(from)}' '#{to_ymd(to)}' #{period}"
      puts cmd
      res = system cmd
      unless res
        puts "Command failed: '#{cmd}'"
        exit 1
      end
    end

    # SIG mentions daily, weekly, monthly, quarterly, yearly
    %w[d w m q y].each do |period|
      cmd = "./db2influx.rb sig_mentions_data #{metrics_dir}/sig_mentions.sql "\
            "'#{to_ymd(from)}' '#{to_ymd(to)}' #{period}"
      puts cmd
      res = system cmd
      unless res
        puts "Command failed: '#{cmd}'"
        exit 1
      end
    end

    # PRs merged per repo daily, weekly, monthly, quarterly, yearly
    %w[d w m q y].each do |period|
      cmd = "./db2influx.rb prs_merged_data #{metrics_dir}/prs_merged.sql "\
            "'#{to_ymd(from)}' '#{to_ymd(to)}' #{period}"
      puts cmd
      res = system cmd
      unless res
        puts "Command failed: '#{cmd}'"
        exit 1
      end
    end

    # All PRs merged hourly, daily, weekly, monthly, quarterly, yearly
    %w[h d w m q y].each do |period|
      cmd = "./db2influx.rb all_prs_merged_#{period} #{metrics_dir}/all_prs_merged.sql "\
            "'#{to_ymdhms(from)}' '#{to_ymdhms(to)}' #{period}"
      puts cmd
      res = system cmd
      unless res
        puts "Command failed: '#{cmd}'"
        exit 1
      end
    end

    # Time opened to merged (number of hours) daily, weekly, monthly, quarterly, yearly
    %w[d w m q y].each do |period|
      cmd = "./db2influx.rb hours_pr_open_to_merge_#{period} #{metrics_dir}/opened_to_merged.sql "\
            "'#{to_ymd(from)}' '#{to_ymd(to)}' #{period}"
      puts cmd
      res = system cmd
      unless res
        puts "Command failed: '#{cmd}'"
        exit 1
      end
    end
  end

  puts 'Sync success'
end

sync(ARGV)
# rubocop:enable Style/GlobalVars
