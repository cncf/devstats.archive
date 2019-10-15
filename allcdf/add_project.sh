#!/bin/bash
# TSDB=1 (will update TSDB)
# FORCEADDALL (will add/merge project into all even if its repo is already present)
# USE_FLAGS=1 (will check devstats running flag and abort when set, then it will clear provisioned flag for the time of adding new metric and then set it)
set -o pipefail
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: You need to provide project name and repo name as arguments"
  exit 1
fi
if [ "$2" = "-" ]
then
  exit 0
fi
if [ -z "$PG_PASS" ]
then
  echo "$0: You need to set PG_PASS environment variable to run this script"
  exit 2
fi
exists=`./devel/db.sh psql postgres -tAc "select 1 from pg_database WHERE datname = 'allcdf'"` || exit 3
if [ -z "$exists" ]
then
  echo "All CDF Project database doesn't exist"
  exit 0
fi
added=`./devel/db.sh psql allcdf -tAc "select name from gha_repos where name = '$2'"` || exit 4
if [ ! -z "$added" ]
then
  echo "Project '$1' is already present in 'All CDF', repo '$2' exists"
  if [ -z "$FORCEADDALL" ]
  then
    exit 0
  else
    echo 'Adding/merging anyway'
  fi
fi

function finish {
  sync_unlock.sh
}

function finish_flags {
  if [ ! -z "$USE_FLAGS" ]
  then
    ./devel/set_flag.sh allprj provisioned || exit 21
  else
    echo 'Not setting provisioned flag'
  fi
}

if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi

if [ ! -z "$USE_FLAGS" ]
then
  ./devel/wait_flag.sh allprj devstats_running 0 || exit 19
  ./devel/clear_flag.sh allprj provisioned || exit 20
  trap finish_flags EXIT
else
  echo 'Not checking running flag and clearing provisioned flag'
fi

echo "merging $1 into allcdf"
GHA2DB_INPUT_DBS="$1" GHA2DB_OUTPUT_DB="allcdf" merge_dbs || exit 11
PG_DB="allcdf" ./devel/remove_db_dups.sh || exit 12
if [ -f "./allcdf/get_repos.sh" ]
then
  ./allcdf/get_repos.sh || exit 13
else
  GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/get_repos.sh || exit 14
fi

if [ -f "./allcdf/setup_repo_groups.sh" ]
then
  ./allcdf/setup_repo_groups.sh || exit 15
else
  GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/setup_repo_groups.sh || exit 16
fi

if [ ! -z "$TSDB" ]
then
  echo "regenerating allcdf TS database"
  if [ -f "./allcdf/reinit.sh" ]
  then
    ./allcdf/reinit.sh || exit 17
  else
    GHA2DB_PROJECT=allcdf PG_DB=allcdf ./shared/reinit.sh || exit 18
  fi
fi
echo "$0: $1 finished"
