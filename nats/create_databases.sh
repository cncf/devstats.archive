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
projdb=nats
function finish {
    rm -rf "$projdb.dump" >/dev/null 2>&1
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
if [ ! -z "$PDB" ]
then
  exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '$projdb'"` || exit 1
  if ( [ ! -z "$PDROP" ] && [ "$exists" = "1" ] )
  then
    echo "dropping postgres database $projdb"
    sudo -u postgres psql -c "drop database $projdb" || exit 2
  fi
  exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '$projdb'"` || exit 3
  if [ ! "$exists" = "1" ]
  then
    echo "creating postgres database $projdb"
    sudo -u postgres psql -c "create database $projdb" || exit 4
    sudo -u postgres psql -c "grant all privileges on database \"$projdb\" to gha_admin" || exit 5
    if [ ! -z "$GET" ]
    then
      echo "attempt to fetch postgres database $projdb from backup"
      wget "https://cncftest.io/$projdb.dump" || exit 6
      sudo -u postgres pg_restore -d "$projdb" "$projdb.dump" || exit 7
      rm -f "$proj.dump" || exit 8
    else
      echo "generating postgres database $projdb"
      GHA2DB_MGETC=y ./$proj/psql.sh || exit 10
    fi
  else
    echo "postgres database $projdb already exists"
  fi
else
  echo "postgres database $projdb generation skipped"
fi
if [ ! -z "$IDB" ]
then
  if [ ! -z "$IDROP" ]
  then
    echo "recreating influx database $projdb"
    ./grafana/influxdb_recreate.sh "$projdb" || exit 10
  fi
  echo "regenerating influx database $projdb"
  ./$proj/reinit.sh || exit 11
else
  echo "influxdb database $projdb generation skipped"
fi
echo 'finished'
