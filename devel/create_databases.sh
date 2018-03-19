#!/bin/bash
# PDB=1 (will generate Postgres DB)
# PDROP=1 (will drop & create Postgres DB)
# GET=1 (will use Postgres DB backup)
# GAPS=1 (will update metrics/$PROJ/gaps.yaml with Top repo groups from PSQL database)
# IDB=1 (will generate Influx DB)
# IDROP=1 (will drop & create Influx DB)
lim=70
set -o pipefail
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 1
fi
if ( [ -z "$PROJ" ] || [ -z "$PROJDB" ] )
then
  echo "$0: You need to set PROJ, PROJDB environment variables to run this script"
  exit 2
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
  exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '$PROJDB'"` || exit 3
  if ( [ ! -z "$PDROP" ] && [ "$exists" = "1" ] )
  then
    echo "dropping postgres database $PROJDB"
    sudo -u postgres psql -c "drop database $PROJDB" || exit 4
  fi
  exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = '$PROJDB'"` || exit 5
  if [ ! "$exists" = "1" ]
  then
    echo "creating postgres database $PROJDB"
    sudo -u postgres psql -c "create database $PROJDB" || exit 6
    sudo -u postgres psql -c "grant all privileges on database \"$PROJDB\" to gha_admin" || exit 7
    if [ ! -z "$GET" ]
    then
      echo "attempt to fetch postgres database $PROJDB from backup"
      wget "https://cncftest.io/$PROJDB.dump" || exit 9
      sudo -u postgres pg_restore -d "$PROJDB" "$PROJDB.dump" || exit 10
      rm -f "$PROJ.dump" || exit 11
    else
      echo "generating postgres database $PROJDB"
      GHA2DB_MGETC=y ./$PROJ/psql.sh || exit 12
    fi
    ./devel/ro_user_grants.sh "$PROJDB" || exit 8
    dbcreated=1
  else
    echo "postgres database $PROJDB already exists"
  fi
else
  echo "postgres database $PROJDB generation skipped"
fi
if ( [ ! -z "$GAPS" ] && [ ! -z "$dbcreated" ] )
then
  sql=`sed -e "s/{{lim}}/$lim/g" ./util_sql/top_repo_groups.sql`
  repo_groups=`sudo -u postgres psql "$PROJDB" -tAc "$sql"`
  MODE=rs FROM=';;;(.*) # {{repo_groups}}' TO=";;;$repo_groups # {{repo_groups}}" ./replacer ./metrics/$PROJ/gaps.yaml || exit 13
fi
if [ ! -z "$IDB" ]
then
  exists=`echo 'show databases' | influx -host $IDB_HOST -username gha_admin -password $IDB_PASS | grep $PROJDB`
  if ( [ ! -z "$IDROP" ] && [ ! -z "$exists" ] )
  then
    echo "dropping influx database $PROJDB"
    ./grafana/influxdb_drop.sh "$PROJDB" || exit 14
  fi
  exists=`echo 'show databases' | influx -host $IDB_HOST -username gha_admin -password $IDB_PASS | grep $PROJDB`
  if [ -z "$exists" ]
  then
    echo "generating influx database $PROJDB"
    ./grafana/influxdb_recreate.sh "$PROJDB" || exit 15
    ./$PROJ/reinit.sh || exit 16
  else
    echo "influx database $PROJDB already exists"
  fi
else
  echo "influxdb database $PROJDB generation skipped"
fi
echo "$0: $PROJ finished"
