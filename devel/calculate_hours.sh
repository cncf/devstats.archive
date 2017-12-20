#!/bin/sh
if [ -z "${PG_DB}" ]
then
  echo "You need to set PG_DB environment variable to run this script"
  exit 1
fi
if [ -z "${IDB_DB}" ]
then
  echo "You need to set IDB_DB environment variable to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "args: 'YYYY-MM-DD HH' 'YYYY-MM-DD HH'"
  exit 1
fi
if [ -z "$2" ]
then
  echo "args: 'YYYY-MM-DD HH' 'YYYY-MM-DD HH'"
  exit 1
fi
# PG_DB=gha IDB_DB=gha PG_PASS=... IDB_PASS=... IDB_HOST=172.17.0.1 GHA2DB_DEBUG=1 ./devel/calculate_hours.sh '2017-12-20 11' '2017-12-20 13'
./db2influx events_h metrics/kubernetes/events.sql "$1" "$2" h
