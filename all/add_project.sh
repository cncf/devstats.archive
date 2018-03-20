#!/bin/bash
# IDB=1 (will update InfluxDB)
# IGET=1 (attempt to fetch Influx database from the test server)
# AGET=1 (will fetch allprj database from backup - not recommended because local merge is faster)
set -o pipefail
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: You need to provide project name and repo name as arguments"
  exit 1
fi
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 2
fi
if ( [ ! -z "$IGET" ] && [ -z "$IDB_PASS_SRC" ] )
then
  echo "$0: You need to set IDB_PASS_SRC environment variable when using IGET"
  exit 3
fi
exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = 'allprj'"` || exit 4
if [ -z "$exists" ]
then
  echo "All CNCF Project database doesn't exist"
  exit 0
fi
added=`sudo -u postgres psql allprj -tAc "select name from gha_repos where name = '$2'"` || exit 5
if [ ! -z "$added" ]
then
  echo "Project '$1' is already present in 'All CNCF', repo '$2' exists"
  exit 0
fi
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
if [ ! -z "$AGET" ]
then
  echo "attempt to fetch postgres database allprj from backup"
  wget "https://cncftest.io/allprj.dump" || exit 6
  sudo -u postgres pg_restore -d allprj allprj.dump || exit 7
  rm -f allprj.dump || exit 8
  echo "allprj backup restored"
  AGOT=1
else
  echo "merging $1 into allprj"
  GHA2DB_INPUT_DBS="$1" GHA2DB_OUTPUT_DB="allprj" ./merge_pdbs || exit 9
  PG_DB="allprj" ./devel/remove_db_dups.sh || exit 10
  ./all/get_repos.sh || exit 11
  ./all/setup_repo_groups.sh || exit 12
fi
if [ -z "$IDB" ]
then
  ./all/top_n_repos_groups.sh 70 > out || exit 13
  ./all/top_n_companies 70 >> out || exit 14
  cat out
  echo 'Please update ./metrics/all/gaps*.yaml with new companies & repo groups data (also dont forget repo groups).'
  echo 'Then run ./all/reinit.sh.'
  echo 'Top 70 repo groups & companies are saved in "out" file.'
else
  if [ -z "$IGET" ]
  then
    echo "regenerating allprj influx database"
    ./all/reinit.sh || exit 15
  else
    echo 'fetching allprj database from cncftest.io (into allprj_temp database)'
    ./grafana/influxdb_recreate.sh allprj_temp || exit 16
    IDB_HOST_SRC=cncftest.io IDB_USER_SRC=ro_user IDB_DB_SRC=allprj IDB_DB_DST=allprj_temp ./idb_backup || exit 17
    echo 'copying allprj_temp database to allprj'
    ./grafana/influxdb_recreate.sh allprj || exit 18
    unset IDB_PASS_SRC
    IDB_DB_SRC=allprj_temp IDB_DB_DST=allprj ./idb_backup || exit 19
    ./grafana/influxdb_drop.sh allprj_temp || exit 20
  fi
  if [ ! -z "$AGOT" ]
  then
    GHA2DB_PROJECT=all PG_DB=allprj IDB_DB=allprj ./gha2db_sync || exit 21
  fi
fi
echo "$0: $1 finished"
