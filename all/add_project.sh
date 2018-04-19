#!/bin/bash
# IDB=1 (will update InfluxDB)
# IGET=1 (attempt to fetch Influx database from the test server)
# AGET=1 (will fetch allprj database from backup - not recommended because local merge is faster)
# SKIPTEMP=1 will skip optional step (local:allprj_temp) when copying IDB backup remote:allprj ->local:allprj_temp -> local:allprj
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
if [ -z "$HOST_SRC" ]
then
  HOST_SRC=cncftest.io
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
  echo 'dropping and recreating postgres variables'
  sudo -u postgres psql allprj -c "delete from gha_vars" || exit 24
  GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 ./pdb_vars || exit 25
  echo "allprj backup restored"
  AGOT=1
else
  echo "merging $1 into allprj"
  GHA2DB_INPUT_DBS="$1" GHA2DB_OUTPUT_DB="allprj" ./merge_pdbs || exit 9
  PG_DB="allprj" ./devel/remove_db_dups.sh || exit 10
  if [ -f "./all/get_repos.sh" ]
  then
    ./all/get_repos.sh || exit 11
  else
    GHA2DB_PROJECT=all PG_DB=allprj ./shared/get_repos.sh || exit 26
  fi
  if [ -f "./all/setup_repo_groups.sh" ]
  then
    ./all/setup_repo_groups.sh || exit 12
  else
    GHA2DB_PROJECT=all PG_DB=allprj ./shared/setup_repo_groups.sh || exit 27
  fi
fi
if [ -z "$IDB" ]
then
  if [ -f "./all/top_n_repos_groups.sh" ]
  then
    ./all/top_n_repos_groups.sh 70 > out || exit 13
  else
    GHA2DB_PROJECT=all PG_DB=allprj ./shared/top_n_repos_groups.sh 70 > out || exit 18
  fi
  if [ -f "./all/top_n_companies.sh" ]
  then
    ./all/top_n_companies.sh 70 > out || exit 29
  else
    GHA2DB_PROJECT=all PG_DB=allprj ./shared/top_n_companies.sh 70 >> out || exit 30
  fi
  cat out
  echo 'Please update ./metrics/all/gaps*.yaml with new companies & repo groups data (also dont forget repo groups).'
  echo 'Then run reinit.sh.'
  echo 'Top 70 repo groups & companies are saved in "out" file.'
else
  if [ -z "$IGET" ]
  then
    echo "regenerating allprj influx database"
    if [ -f "./all/reinit.sh" ]
    then
      ./all/reinit.sh || exit 15
    else
      GHA2DB_PROJECT=all PG_DB=allprj IDB_DB=allprj ./shared/reinit.sh || exit 24
    fi
  else
    echo 'fetching allprj database from cncftest.io (into allprj_temp database)'
    if [ -z "$SKIPTEMP" ]
    then
      ./grafana/influxdb_recreate.sh allprj_temp || exit 16
      IDB_HOST_SRC=$HOST_SRC IDB_USER_SRC=ro_user IDB_DB_SRC=allprj IDB_DB_DST=allprj_temp ./idb_backup || exit 17
      echo 'removing influx variables received from the backup'
      echo "drop series from vars" | influx -host "${IDB_HOST}" -username gha_admin -password "$IDB_PASS" -database allprj_temp || exit 22
      echo 'regenerating influx variables'
      GHA2DB_LOCAL=1 GHA2DB_PROJECT=all IDB_DB=allprj_temp ./idb_vars || exit 23
      echo 'copying allprj_temp database to allprj'
      ./grafana/influxdb_recreate.sh allprj || exit 18
      unset IDB_PASS_SRC
      IDB_DB_SRC=allprj_temp IDB_DB_DST=allprj ./idb_backup || exit 19
      ./grafana/influxdb_drop.sh allprj_temp || exit 20
    else
      ./grafana/influxdb_recreate.sh allprj || exit 27
      IDB_HOST_SRC=$HOST_SRC IDB_USER_SRC=ro_user IDB_DB_SRC=allprj IDB_DB_DST=allprj ./idb_backup || exit 28
      echo 'removing influx variables received from the backup'
      echo "drop series from vars" | influx -host "${IDB_HOST}" -username gha_admin -password "$IDB_PASS" -database allprj || exit 29
      echo 'regenerating influx variables'
      GHA2DB_LOCAL=1 GHA2DB_PROJECT=all IDB_DB=allprj ./idb_vars || exit 30
    fi
  fi
  if [ ! -z "$AGOT" ]
  then
    GHA2DB_PROJECT=all PG_DB=allprj IDB_DB=allprj ./gha2db_sync || exit 21
  fi
fi
echo "$0: $1 finished"
