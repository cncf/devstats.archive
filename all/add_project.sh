#!/bin/bash
# IDB=1 (will update InfluxDB)
set -o pipefail
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: You need to provide project name and org name as arguments"
  exit 1
fi
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 2
fi
exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = 'allprj'"` || exit 3
if [ ! "$exists" = "1" ]
then
  echo "All CNCF Project database doesn't exist"
  exit 0
fi
added=`sudo -u postgres psql allprj -tAc "select login from gha_orgs where login = '$2'"` || exit 4
if [ "$added" = "$2" ]
then
  echo "Project '$1' is already present in 'All CNCF', org '$2' exists"
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
GHA2DB_INPUT_DBS="$1" GHA2DB_OUTPUT_DB="allprj" ./merge_pdbs || exit 5
PG_DB="allprj" ./devel/remove_db_dups.sh || exit 6
./all/get_repos.sh || exit 7
./all/setup_repo_groups.sh || exit 8
if [ -z "$IDB" ]
then
  ./all/top_n_repos_groups.sh 70 > out || exit 9
  ./all/top_n_companies 70 >> out || exit 10
  cat out
  echo 'Please update ./metrics/all/gaps*.yaml with new companies & repo groups data (also dont forget repo groups).'
  echo 'Then run ./all/reinit.sh.'
  echo 'Top 70 repo groups & companies are saved in "out" file.'
else
  ./all/reinit.sh || exit 11
fi
echo 'OK'
