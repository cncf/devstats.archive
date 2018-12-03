#!/bin/bash
# PDB=1 (will generate Postgres DB)
# TSDB=1 (will generate TS DB)
# PDROP=1 (will drop & create Postgres DB)
# GET=1 (will use Postgres DB backup)
lim=70
set -o pipefail
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if ( [ -z "$PROJ" ] || [ -z "$PROJDB" ] )
then
  echo "$0: You need to set PROJ, PROJDB environment variables to run this script"
  exit 2
fi
if [ -z "$HOST_SRC" ]
then
  HOST_SRC=teststats.cncf.io
fi
function finish {
    rm -rf "$PROJDB.dump" >/dev/null 2>&1
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
  exists=`./devel/db.sh psql -tAc "select 1 from pg_database where datname = '$PROJDB'"` || exit 3
  if ( [ ! -z "$PDROP" ] && [ "$exists" = "1" ] )
  then
    echo "dropping postgres database $PROJDB"
    ./devel/db.sh psql postgres -c "select pg_terminate_backend(pid) from pg_stat_activity where datname = '$PROJDB'" || exit 4
    ./devel/db.sh psql postgres -c "drop database $PROJDB" || exit 5
  fi
  exists=`./devel/db.sh psql -tAc "select 1 from pg_database where datname = '$PROJDB'"` || exit 6
  if [ ! "$exists" = "1" ]
  then
    echo "creating postgres database $PROJDB"
    ./devel/db.sh psql postgres -c "create database $PROJDB" || exit 7
    ./devel/db.sh psql postgres -c "grant all privileges on database \"$PROJDB\" to gha_admin" || exit 8
    ./devel/db.sh psql "$PROJDB" -c "create extension if not exists pgcrypto" || exit 23
    if [ ! -z "$GET" ]
    then
      echo "attempt to fetch postgres database $PROJDB from backup"
      wget "https://teststats.cncf.io/$PROJDB.dump" || exit 9
      ./devel/db.sh pg_restore -d "$PROJDB" "$PROJDB.dump" || exit 10
      rm -f "$PROJDB.dump" || exit 11
      echo 'dropping and recreating postgres variables'
      ./devel/db.sh psql "$PROJDB" -c "delete from gha_vars" || exit 12
      GHA2DB_PROJECT="$PROJ" PG_DB="$PROJDB" GHA2DB_LOCAL=1 ./vars || exit 13
      GHA2DB_PROJECT="$PROJ" PG_DB="$PROJDB" GHA2DB_LOCAL=1 GHA2DB_VARS_FN_YAML="sync_vars.yaml" ./vars || exit 13
      GOT=1
    else
      echo "generating postgres database $PROJDB"
      GHA2DB_MGETC=y ./$PROJ/psql.sh || exit 14
      ./devel/ro_user_grants.sh "$PROJDB" || exit 15
      ./devel/psql_user_grants.sh "devstats_team" "$PROJDB" || exit 16
      dbcreated=1
      cron_db_backup.sh "$PROJDB" || exit 17
    fi
  else
    echo "postgres database $PROJDB already exists"
  fi
else
  echo "postgres database $PROJDB generation skipped"
fi
if [ ! -z "$TSDB" ]
then
  exists=`./devel/db.sh psql -tAc "select 1 from pg_database where datname = '$PROJDB'"` || exit 3
  if [ ! "$exists" = "1" ]
  then
    echo "$0: '$PROJDB' must exist to initialize TSDB"
    exit 21
  fi
  exists=`./devel/db.sh psql "$PROJDB" -tAc "select to_regclass('sevents_h')"` || exit 22
  if [ "$exists" = "sevents_h" ]
  then
    echo "time series data already exists in $PROJDB"
  else
    echo "generating TSDB database $PROJDB"
    if [ -f "./$proj/reinit.sh" ]
    then
      ./$PROJ/reinit.sh || exit 18
    else
      GHA2DB_PROJECT=$PROJ PG_DB=$PROJDB ./shared/reinit.sh || exit 19
    fi
    REINIT=1
  fi
  if [ ! -z "$GOT" ]
  then
    GHA2DB_PROJECT="$PROJ" PG_DB="$PROJDB" ./gha2db_sync || exit 20
  fi
  if [ ! -z "$REINIT" ]
  then
    cron_db_backup.sh "$PROJDB" || exit 24
  fi
else
  echo "TS database $PROJDB generation skipped"
fi
echo "$0: $PROJ finished"
