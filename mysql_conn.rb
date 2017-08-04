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

def conn
  # Connect to database
  Mysql2::Client.new(
    host: ENV['MYSQL_HOST'] || 'localhost',
    port: (ENV['MYSQL_PORT'] || '3306').to_i,
    database: ENV['MYSQL_DB'] || 'gha',
    username: ENV['MYSQL_USER'] || 'gha_admin',
    password: ENV['MYSQL_PASS'] || 'password'
  )
rescue Mysql2::Error => e
  puts e.message
  exit(1)
end

def exec_sql(c, query)
  c.query(query)
end
