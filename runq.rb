#!/usr/bin/env ruby

# rubocop:disable Style/GlobalVars
require 'pry'
require './conn' # All database details & setup there

# rubocop:disable Lint/Debugger
def runq(sql_file)
  # Connect to database
  c = conn
  sql = File.read(sql_file)
  res = exec_sql(c, sql)
  return unless res.count.positive?
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
  puts "Rows: #{res.count}"
rescue $DBError => e
  puts e.message
  binding.pry
ensure
  c&.close
end
# rubocop:enable Lint/Debugger

if ARGV.count < 1
  puts 'Required SQL file name'
  exit 1
end

runq(ARGV.first)

# rubocop:enable Style/GlobalVars
