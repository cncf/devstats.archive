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

# rubocop:disable Style/GlobalVars
$pg = true
$DBError = PG::Error

def conn
  # Connect to database
  PG::Connection.new(
    host: ENV['PG_HOST'] || 'localhost',
    port: (ENV['PG_PORT'] || '5432').to_i,
    dbname: ENV['PG_DB'] || 'gha',
    user: ENV['PG_USER'] || 'gha_admin',
    password: ENV['PG_PASS'] || 'password'
  )
rescue PG::Error => e
  puts e.message
  exit(1)
end

def exec_sql(c, query)
  puts query if ENV['GHA2DB_QOUT']
  c.exec(query)
end

# DB specific wrappers:

# returns for n:
# n=1 -> values($1)
# n=10 -> values($1, $2, $3, .., $10)
def n_values(n)
  s = 'values('
  (1..n).each { |i| s += "$#{i}, " }
  s[0..-3] + ')'
end

def n_value(index)
  "$#{index}"
end

def insert_ignore(query)
  "insert #{query} on conflict do nothing"
end

def create_table(tdef)
  "create table #{tdef}".gsub(
    '{{ts}}',
    'timestamp'
  )
end

def parse_timestamp(tval)
  Time.parse(tval).utc
end
# rubocop:enable Style/GlobalVars
