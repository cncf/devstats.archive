#!/bin/bash
# TSDB=1 (will update TSDB)
# AGET=1 (will fetch allprj database from backup)
set -o pipefail
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: You need to provide project name and repo name as arguments"
  exit 1
fi
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 2
fi
exists=`./devel/db.sh psql -tAc "select 1 from pg_database WHERE datname = 'allprj'"` || exit 3
if [ -z "$exists" ]
then
  echo "All CNCF Project database doesn't exist"
  exit 0
fi
added=`./devel/db.sh psql allprj -tAc "select name from gha_repos where name = '$2'"` || exit 4
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
  wget "https://teststats.cncf.io/allprj.dump" || exit 5
  ./devel/restore_db.sh allprj || exit 6
  rm -f allprj.dump || exit 7
  echo 'dropping and recreating postgres variables'
  ./devel/db.sh psql allprj -c "delete from gha_vars" || exit 8
  GHA2DB_PROJECT=all PG_DB=allprj GHA2DB_LOCAL=1 ./vars || exit 9
  echo "allprj backup restored"
  GHA2DB_PROJECT=all PG_DB=allprj ./gha2db_sync || exit 10
  exit 0
else
  echo "merging $1 into allprj"
  GHA2DB_INPUT_DBS="$1" GHA2DB_OUTPUT_DB="allprj" ./merge_dbs || exit 11
  PG_DB="allprj" ./devel/remove_db_dups.sh || exit 12
  if [ -f "./all/get_repos.sh" ]
  then
    ./all/get_repos.sh || exit 13
  else
    GHA2DB_PROJECT=all PG_DB=allprj ./shared/get_repos.sh || exit 14
  fi
  if [ -f "./all/setup_repo_groups.sh" ]
  then
    ./all/setup_repo_groups.sh || exit 15
  else
    GHA2DB_PROJECT=all PG_DB=allprj ./shared/setup_repo_groups.sh || exit 16
  fi
fi
if [ ! -z "$TSDB" ]
then
  echo "regenerating allprj TS database"
  if [ -f "./all/reinit.sh" ]
  then
    ./all/reinit.sh || exit 17
  else
    GHA2DB_PROJECT=all PG_DB=allprj ./shared/reinit.sh || exit 18
  fi
fi
echo "$0: $1 finished"
