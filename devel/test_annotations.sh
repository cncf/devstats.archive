if [ -z "${GHA2DB_PROJECT}" ]
then
  echo "You need to set GHA2DB_PROJECT environment variable to run this script"
  exit 1
fi
IDB_HOST=172.17.0.1 ./grafana/influxdb_recreate.sh test || exit 1
GHA2DB_LOCAL=1 GHA2DB_DEBUG=1 IDB_DB=test IDB_HOST=172.17.0.1 ./annotations
influx -host 172.17.0.1 -username gha_admin -password ${IDB_PASS} -database test -execute 'select * from annotations'
influx -host 172.17.0.1 -username gha_admin -password ${IDB_PASS} -database test -execute 'select * from quick_ranges'
