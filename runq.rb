#!/usr/bin/env ruby

# rubocop:disable Style/GlobalVars
require 'pry'
require './conn' # All database details & setup there

# rubocop:disable Lint/Debugger
def runq(sql_file, params)
  # SQL arguments parse
  raise Exception, 'Must provide correct parameter value pairs.' if (params.count % 2).positive?
  replaces = {}
  param_name = nil
  params.each_with_index do |param, index|
    if (index % 2).zero?
      replaces[param] = nil
      param_name = param
    else
      replaces[param_name] = param
      param_name = nil
    end
  end

  # Read and eventually transform SQL file.
  sql = File.read(sql_file)
  replaces.each do |from, to|
    sql.gsub!(from, to)
  end

  # Connect to database
  con = conn

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
  puts 'Required SQL file name [param1 value1 [param2 value2 ...]]'
  exit 1
end

runq(ARGV.first, ARGV[1..-1])

# rubocop:enable Style/GlobalVars
