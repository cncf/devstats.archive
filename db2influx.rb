#!/usr/bin/env ruby

require './time_stuff'
# All Postgres database details & setup there
require './conn'
# All InfluxDB database details & setup there
require './idb_conn'

# rubocop:disable Style/GlobalVars
# db2influx --> psql/mysql to InfluxDB time series
# Debug level can be set via GHA2DB_DEBUG
$debug = ENV['GHA2DB_DEBUG'] ? ENV['GHA2DB_DEBUG'].to_i : 0

$thr_n = Etc.nprocessors
puts "Available #{$thr_n} processors"

# Use environment variable to have singlethreaded version
$thr_n = 1 if ENV['GHA2DB_ST']

# This receives SIG mentions row and period name
# Returns InfluxDB series name and value
def sig_mentions_data(sig_row, period)
  [
    sig_row['sig'].tr('-', '_') + '_' + period,
    sig_row.values.last.to_i
  ]
end

# This receives PRs merged row and period name
# Return InfluxDB series name & value
def prs_merged_data(prs_row, period)
  [
    'prs_' + prs_row['repo_name'].tr('-/.', '_') + '_' + period,
    prs_row.values.last.to_i
  ]
end

def threaded_db2influx(series_name_or_func, sql, period, from, to)
  sqlc = conn
  ic = idb_conn
  s_from = from.to_s[0..-7]
  s_to = to.to_s[0..-7]
  q = sql.gsub('{{from}}', s_from).gsub('{{to}}', s_to)
  r = exec_sql(sqlc, q)
  return if r.count.zero?
  # ts = (from.to_i + to.to_i) / 2
  ts = from.to_i
  # ts = to.to_i
  if r.count == 1 && r.first.keys.count == 1
    value = r.first.values.first.to_i
    name = series_name_or_func
    puts "#{from.to_date} - #{to.to_date} -> #{name}, #{value}" if $debug.positive?
    data = {
      values: { value: value },
      timestamp: ts
    }
    ic.write_point(name, data)
  elsif r.count.positive? && r.first.keys.count == 2
    r.each do |row|
      name, value = __send__(series_name_or_func, row, period)
      puts "#{from.to_date} - #{to.to_date} -> #{name}, #{value}" if $debug.positive?
      data = {
        values: { value: value },
        timestamp: ts
      }
      ic.write_point(name, data)
    end
  else
    raise(
      Exception,
      "Wrong query:\n#{q}\nMetrics query should either return single row "\
      'with single value or at least 1 row, each with two values'
    )
  end
rescue InfluxDB::ConnectionError => e
  puts e.message
  exit(1)
rescue $DBError => e
  puts e.message
  exit(1)
ensure
  sqlc&.close
end

def db2influx(series_name_or_func, sql_file, from, to, interval_abbr)
  # Connect to database
  sql = File.read(sql_file)
  d_from = Time.parse(from).utc
  d_to = Time.parse(to).utc
  interval =
    case interval_abbr.downcase
    when 'h' then 'hour'
    when 'd' then 'day'
    when 'w' then 'week'
    when 'm' then 'month'
    when 'q' then 'quarter'
    when 'y' then 'year'
    else raise Exception, "Unknown interval #{interval}"
    end
  d_from = __send__("#{interval}_start", d_from)
  d_to = __send__("next_#{interval}_start", d_to)
  puts "Running: #{d_from} - #{d_to} with interval #{interval}"
  dt = d_from
  if $thr_n > 1
    thr_pool = []
    while dt < d_to
      ndt = __send__("next_#{interval}_start", dt)
      thr =
        Thread.new(dt, ndt) do |adtf, adtt|
          threaded_db2influx(series_name_or_func, sql, interval_abbr, adtf, adtt)
        end
      thr_pool << thr
      dt = ndt
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
    while dt < d_to
      ndt = __send__("next_#{interval}_start", dt)
      threaded_db2influx(series_name_or_func, sql, interval_abbr, dt, ndt)
      dt = ndt
    end
  end
  puts 'All done.'
rescue => e
  puts e.message
  raise e
end

if ARGV.count < 5
  puts 'Required series name, SQL file name, from, to, period '\
       '[series_name_or_func some.sql \'2015-08-03\' \'2017-08-21\' d|w|m|y'
  puts 'Series name (series_name_or_func) will become exact series name if '\
       'query return just single numeric value'
  puts 'For queries returning multiple rows \'series_name_or_func\' will be used as function that'
  puts 'receives data row and period and returns name and value for it'
  exit 1
end

db2influx(ARGV[0], ARGV[1], ARGV[2], ARGV[3], ARGV[4])

# rubocop:enable Style/GlobalVars
