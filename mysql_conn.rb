require 'mysql2'
require 'pry'

# DB setup:
# sudo apt-get install mysql-server
# sudo mysql_secure_installation
# mysql -uusername -ppassword
# create database gha;
# create user 'gha_admin'@'localhost' identified by 'your_password_here';
# grant all privileges on gha.* to 'gha_admin'@'localhost';
# flush privileges;
# GHA2DB_MYSQL=1 MYSQL_PASS='pwd' ./structure.rb
# mysql -uusername -ppassword gha

# Defaults are:
# Database host: environment variable MYSQL_HOST or `localhost`
# Database port: MYSQL_PORT or 5432
# Database name: MYSQL_DB or 'gha'
# Database user: MYSQL_USER or 'gha_admin'
# Database password: MYSQL_PASS || 'password'

# rubocop:disable Style/GlobalVars
$mysql = true
$DBError = Mysql2::Error

def conn
  # Connect to database
  Mysql2::Client.new(
    host: ENV['MYSQL_HOST'] || 'localhost',
    port: (ENV['MYSQL_PORT'] || '3306').to_i,
    database: ENV['MYSQL_DB'] || 'gha',
    username: ENV['MYSQL_USER'] || 'gha_admin',
    password: ENV['MYSQL_PASS'] || 'password',
    reconnect: true,
    init_commant: 'set names utf8mb4 collate utf8mb4_unicode_ci'
  )
rescue Mysql2::Error => e
  puts e.message
  exit(1)
end

def exec_sql(c, query)
  puts query if ENV['GHA2DB_QOUT']
  c.query(query)
end

# DB specific wrappers:

# returns for n:
# n=1 -> values(?)
# n=10 -> values(?, ?, ?, .., ?)
def n_values(n)
  s = 'values('
  s += '?, ' * n
  s[0..-3] + ')'
end

def n_value(_)
  '?'
end

def insert_ignore(query)
  "insert ignore #{query}"
end

def create_table(tdef)
  "create table #{tdef} character set utf8mb4 collate utf8mb4_unicode_ci".gsub(
    '{{ts}}',
    'datetime'
  )
end

def parse_timestamp(tval)
  y = tval[0..3].to_i
  return '1970-01-01 00:00:01' if y < 1970
  return '2038-01-19 03:14:07' if y > 2038
  Time.parse(tval).utc
end
# rubocop:enable Style/GlobalVars
