require 'influxdb'
require 'pry'

# DB setup:
# grafana/grafana/influxdb_setup.sh

# Defaults are:
# Database host: environment variable IDB_HOST or `localhost`
# Database port: IDB_PORT or 8086
# Database name: IDB_DB or 'gha'
# Database user: IDB_USER or 'gha_admin'
# Database password: IDB_PASS || 'password'

def idb_conn
  # Connect to database
  InfluxDB::Client.new(
    ENV['IDB_DB'] || 'gha',
    host: ENV['IDB_HOST'] || 'localhost',
    port: (ENV['IDB_PORT'] || '8086').to_i,
    username: ENV['IDB_USER'] || 'gha_admin',
    password: ENV['IDB_PASS'] || 'password',
    retry: false
  )
rescue => e
  puts [e.class, e.message]
  exit(1)
end
