#!/bin/bash
if [ -z "${PG_DB}" ]
then
  echo "$0: you need to set PG_DB environment variable to run this script"
  exit 1
fi
if [ -z "${GHA2DB_PROJECT}" ]
then
  echo "$0: you need to set GHA2DB_PROJECT environment variable to run this script"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: you need to provide periods to calculate: 'w:f,m:f,q:f,y:f,a_33_34:t'"
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
GHA2DB_LOCAL=1 GHA2DB_SKIP_TAGS=1 GHA2DB_SKIP_ANNOTATIONS=1 GHA2DB_SKIP_COLUMNS=1 GHA2DB_SKIPPDB=1 GHA2DB_RESETTSDB=1 GHA2DB_FORCE_PERIODS="$1" gha2db_sync
