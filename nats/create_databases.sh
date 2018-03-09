#!/bin/bash
# PDB=1 (will generate Postgres DB)
# PDROP=1 (will drop & create Postgres DB)
# GET=1 (will use Postgres DB backup if available)
# IDB=1 (will generate Influx DB)
# IDROP=1 (will drop & create Influx DB - this is also needed to create Influx DB for the first time)
set -o pipefail
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 1
fi
proj=nats
function finish {
    rm -rf "$proj.dump" >/dev/null 2>&1
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
if [ ! -z "$PDB" ]
then
  exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '$proj'"` || exit 1
  if ( [ ! -z "$PDROP" ] && [ "$exists" = "1" ] )
  then
    echo "dropping postgres database $proj"
    sudo -u postgres psql -c "drop database $proj" || exit 2
  fi
  exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '$proj'"` || exit 3
  if [ ! "$exists" = "1" ]
  then
    echo "creating postgres database $proj"
    sudo -u postgres psql -c "create database $proj" || exit 4
    sudo -u postgres psql -c "grant all privileges on database \"$proj\" to gha_admin" || exit 5
    if [ ! -z "$GET" ]
    then
      echo "attempt to fetch postgres database $proj from backup"
      wget "https://cncftest.io/$proj.dump" || exit 6
      sudo -u postgres pg_restore -d "$proj" "$proj.dump" || exit 7
      rm -f "$proj.dump" || exit 8
      echo "updating postgres database $proj received from backup"
      ./$proj/sync.sh || exit 9
    else
      echo "generating postgres database $proj"
      GHA2DB_MGETC=y ./$proj/psql.sh || exit 10
    fi
  else
    echo "postgres database $proj already exists"
  fi
else
  echo "postgres database $proj generation skipped"
fi
if [ ! -z "$IDB" ]
then
  if [ ! -z "$IDROP" ]
  then
    echo "recreating influx database $proj"
    ./grafana/influxdb_recreate.sh "$proj" || exit 10
  fi
  echo "regenerating influx database $proj"
  ./$proj/reinit.sh || exit 11
else
  echo "influxdb database $proj generation skipped"
fi
echo 'finished'
