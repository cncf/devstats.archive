#!/bin/bash
# PDB=1 (will generate Postgres DB)
# PDROP=1 (will drop & create Postgres DB)
# GET=1 (will use Postgres DB backup if available)
# IDB=1 (will generate Influx DB)
# IDROP=1 (will drop & create Influx DB)
proj=nats
projdb=nats
set -o pipefail
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 1
fi
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
  exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '$projdb'"` || exit 2
  if ( [ ! -z "$PDROP" ] && [ "$exists" = "1" ] )
  then
    echo "dropping postgres database $projdb"
    sudo -u postgres psql -c "drop database $projdb" || exit 3
  fi
  exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '$projdb'"` || exit 4
  if [ ! "$exists" = "1" ]
  then
    echo "creating postgres database $projdb"
    sudo -u postgres psql -c "create database $projdb" || exit 5
    sudo -u postgres psql -c "grant all privileges on database \"$projdb\" to gha_admin" || exit 6
    if [ ! -z "$GET" ]
    then
      echo "attempt to fetch postgres database $projdb from backup"
      wget "https://cncftest.io/$projdb.dump" || exit 7
      sudo -u postgres pg_restore -d "$projdb" "$projdb.dump" || exit 8
      rm -f "$proj.dump" || exit 9
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
  exists=`echo 'show databases' | influx -host $IDB_HOST -username gha_admin -password $IDB_PASS | grep $projdb`
  if ( [ ! -z "$IDROP" ] && [ "$exists" = "$projdb" ] )
  then
    echo "dropping influx database $projdb"
    ./grafana/influxdb_drop.sh "$projdb" || exit 11
  fi
  exists=`echo 'show databases' | influx -host $IDB_HOST -username gha_admin -password $IDB_PASS | grep $projdb`
  if [ ! "$exists" = "$projdb" ]
  then
    echo "generating influx database $projdb"
    ./grafana/influxdb_recreate.sh "$projdb" || exit 12
    ./$proj/reinit.sh || exit 13
  else
    echo "influx database $projdb already exists"
  fi
else
  echo "influxdb database $projdb generation skipped"
fi
echo 'finished'
