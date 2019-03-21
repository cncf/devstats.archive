#!/bin/bash
if [ -z "${PG_DB}" ]
then
  echo "You need to set PG_DB environment variable to run this script"
  exit 1
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
if ( [ -z "$1" ] || [ -z "$2" ] )
then
  echo "$0: required comma separated list of metrics to run and start date"
  echo "Example: $0 'events,activity_repo_groups' '2018-04-28'"
  exit 1
fi
GHA2DB_CMDDEBUG=1 GHA2DB_STARTDT_FORCE=1 GHA2DB_ONLY_METRICS="$1" GHA2DB_STARTDT="$2" GHA2DB_LOCAL=1 gha2db_sync
