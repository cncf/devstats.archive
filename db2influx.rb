#!/usr/bin/env ruby

require './time_stuff'
require './conn'  # All Postgres database details & setup there
require './idb_conn' # All InfluxDB database details & setup there

# db2influx --> psql/mysql to InfluxDB time series
# Debug level can be set via GHA2DB_DEBUG
$debug = ENV['GHA2DB_DEBUG'] ? ENV['GHA2DB_DEBUG'].to_i : 0

$thr_n = Etc.nprocessors
puts "Available #{$thr_n} processors"

# Use environment variable to have singlethreaded version
$thr_n = 1 if ENV['GHA2DB_ST']

def threaded_db2influx(series_name, sql, p_name, from, to)
  sqlc = conn
  ic = idb_conn
  s_from = from.to_s[0..-7]
  s_to = to.to_s[0..-7]
  q = sql.gsub('{{from}}', s_from).gsub('{{to}}', s_to)
  r = exec_sql(sqlc, q)
  n = r.first['result'].to_i
  # ts = (from.to_i + to.to_i) / 2
  ts = from.to_i
  # ts = to.to_i
  puts "#{from.to_date} - #{to.to_date} -> #{n}" if $debug
  data = {
    values: { value: n },
    # tags: { period: p_name },
    timestamp: ts
  }
  ic.write_point(series_name, data)
rescue InfluxDB::ConnectionError => e
  puts e.message
  exit(1)
rescue $DBError => e
  puts e.message
  exit(1)
ensure
  sqlc.close if sqlc
end

def db2influx(series_name, sql_file, from, to, interval)
  # Connect to database
  sql = File.read(sql_file)
  d_from = Time.parse(from)
  d_to = Time.parse(to)
  interval = case interval.downcase
    when 'd' then 'day'
    when 'w' then 'week'
    when 'm' then 'month'
    when 'y' then 'year'
    else raise "Unknown interval #{interval}"
  end
  d_from = send("#{interval}_start", d_from)
  d_to = send("next_#{interval}_start", d_to)
  puts "Running: #{d_from} - #{d_to} with interval #{interval}"
  dt = d_from
  if $thr_n > 1
    thr_pool = []
    while dt < d_to
      ndt = send("next_#{interval}_start", dt)
      thr = Thread.new(dt, ndt) { |adtf, adtt| threaded_db2influx(series_name, sql, interval, adtf, adtt) }
      thr_pool << thr
      dt = ndt
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
    while dt < d_to
      ndt = send("next_#{interval}_start", dt)
      threaded_db2influx(series_name, sql, interval, dt, ndt)
      dt = ndt
    end
  end
  puts "All done."
rescue Exception => e
  puts e.message
  raise e
end

if ARGV.count < 5
  puts "Required series name, SQL file name, from, to, period [name some.sql '2015-08-03' '2017-08-21' d|w|m|y"
  exit 1
end

db2influx(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4])

