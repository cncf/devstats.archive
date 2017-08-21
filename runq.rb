#!/usr/bin/env ruby

# rubocop:disable Style/GlobalVars
require 'pry'
require './conn' # All database details & setup there

# rubocop:disable Lint/Debugger
def runq(sql_file)
  # Connect to database
  con = conn
  sql = File.read(sql_file)
  # Results
  results = exec_sql(con, sql)
  unless results.count.positive?
    puts 'Metric returned no data'
    return
  end

  columns = results.first.keys
  column_lengths = {}
  columns.each do |column|
    column_lengths[column] = (
      results.map { |row| (row[column] || '').to_s } + [column]
    ).max_by(&:length).length
  end

  # Upper frame of the header row
  output = '/'
  columns.each do |column|
    fmt = "%-#{column_lengths[column]}s"
    value = '-' * column_lengths[column]
    output += "#{fmt % value}+"
  end
  output = output[0..-2] + "\\\n"
  puts output

  # Header row
  output = '|'
  columns.each do |column|
    fmt = "%-#{column_lengths[column]}s"
    output += "#{fmt % column}|"
  end
  output += "\n"
  puts output

  # Frame between header row and data rows
  output = '+'
  columns.each do |column|
    fmt = "%-#{column_lengths[column]}s"
    value = '-' * column_lengths[column]
    output += "#{fmt % value}+"
  end
  output = output[0..-2] + "+\n"
  puts output

  # Data rows
  results.each do |row|
    output = '|'
    row.each do |column, value|
      fmt = "%-#{column_lengths[column]}s"
      output += "#{fmt % value}|"
    end
    output = output[0..-2] + "|\n"
    puts output
  end

  # Frame below data rows
  output = '\\'
  columns.each do |column|
    fmt = "%-#{column_lengths[column]}s"
    v = '-' * column_lengths[column]
    output += "#{fmt % v}+"
  end
  output = output[0..-2] + "/\n"
  puts output

  # Row count
  puts "Rows: #{results.count}"
rescue $DBError => e
  puts e.message
  binding.pry
ensure
  con&.close
end
# rubocop:enable Lint/Debugger

if ARGV.count < 1
  puts 'Required SQL file name'
  exit 1
end

runq(ARGV.first)

# rubocop:enable Style/GlobalVars
