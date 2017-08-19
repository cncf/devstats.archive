# Global variables to specify which DB is used and error class
# rubocop:disable Style/GlobalVars
$pg = false
$mysql = false
$DBError = nil

if ENV['GHA2DB_PSQL']
  # All PostgreSQL connection details here
  require './pg_conn'
elsif ENV['GHA2DB_MYSQL']
  # All MySQL connection details here
  require './mysql_conn'
else
  raise Exception, 'You need to set `GHA2DB_PSQL` or `GHA2DB_MYSQL` environment variable.'
end
# rubocop:enable Style/GlobalVars
