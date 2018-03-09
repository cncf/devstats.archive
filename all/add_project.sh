#!/bin/bash
# IDB=1 (will update InfluxDB tool)
if [ -z "$1" ]
then
  echo "$0: You need to provide project name as argument"
  exit 1
fi
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 2
fi
function finish {
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
GHA2DB_INPUT_DBS="$1" GHA2DB_OUTPUT_DB="allprj" ./merge_pdbs || exit 3
PG_DB="allprj" ./devel/remove_db_dups.sh || exit 4
./all/get_repos.sh || exit 5
./all/setup_repo_groups.sh || exit 6
if [ -z "$IDB" ]
then
  ./all/top_n_repos_groups.sh 70 > out
  ./all/top_n_companies 70 >> out
  cat out
  echo 'Please update ./metrics/all/gaps*.yaml with new companies & repo groups datai (also dont forget repo groups).'
  echo 'Then run ./all/reinit.sh.'
  echo 'Top 70 repo groups & companies are saved in "out" file.'
else
  ./all/reinit.sh || exit 7
fi
echo 'OK'
