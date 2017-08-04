#!/usr/bin/env ruby

require 'chronic_duration'
require 'time'
require './pg_conn'  # All Postgres database details & setup there
require './idb_conn' # All InfluxDB database details & setup there

# ts2idb --> Time Series to InfluxDB
# Debug level can be set via GHA2PG_DEBUG
$debug = ENV['GHA2PG_DEBUG'] ? ENV['GHA2PG_DEBUG'].to_i : 0

$thr_n = Etc.nprocessors
puts "Available #{$thr_n} processors"

# Use environment variable to have singlethreaded version
$thr_n = 1 if ENV['GHA2PG_ST']

def threaded_ts2idb(sql, p_name, from, to)
  pc = pg_conn
  ic = idb_conn
  s_from = from.to_s[0..-7]
  s_to = to.to_s[0..-7]
  q = sql.gsub('{{from}}', s_from).gsub('{{to}}', s_to)
  r = pc.exec(q)
  n = r.first['result'].to_i
  puts "#{from} - #{to} -> #{n}" if $debug
  data = {
    values: { value: n },
    # tags: { period: p_name },
    timestamp: from.to_i
  }
  ic.write_point('reviewers', data)
rescue InfluxDB::ConnectionError => e
  puts e.message
  exit(1)
rescue PG::Error => e
  puts e.message
  exit(1)
ensure
  pc.close if pc
end

def ts2idb(sql_file, from, to, interval)
  # Connect to database
  sql = File.read(sql_file)
  d_from = Time.parse(from)
  d_to = Time.parse(to)
  s_int = ChronicDuration.parse(interval)
  puts "Running: #{d_from} - #{d_to} with #{interval} --> #{s_int}s"
  dt = d_from
  if $thr_n > 1
    thr_pool = []
    while dt <= d_to
      thr = Thread.new(dt) { |adt| threaded_ts2idb(sql, interval, adt, adt + s_int) }
      thr_pool << thr
      dt = dt + s_int
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
      threaded_ts2idb(sql, interval, dt, dt + s_int)
      dt = dt + s_int
    end
  end
  puts "All done."
rescue Exception => e
  puts e.message
end

if ARGV.count < 4
  puts "Required SQL file name, from, to, period [some.sql '2015-08-01 00:00:00' '2017-09-01 00:00:00' '1 month'"
  exit 1
end

ts2idb(ARGV[0], ARGV[1], ARGV[2], ARGV[3])

