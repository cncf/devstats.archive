IDB_HOST=172.17.0.1 ./grafana/influxdb_recreate.sh test || exit 1
GHA2DB_LOCAL=1 GHA2DB_DEBUG=1 GHA2DB_PROJECT=kubernetes IDB_DB=test IDB_HOST=172.17.0.1 ./annotations 2014-01-01
