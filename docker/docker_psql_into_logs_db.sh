#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
# devstats here is a log database name
./devel/db.sh psql -h 172.17.0.1 -p 65432 devstats
