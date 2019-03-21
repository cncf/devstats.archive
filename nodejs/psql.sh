#!/bin/bash
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
set -o pipefail
> errors.txt
> run.log
GHA2DB_PROJECT=nodejs PG_DB=nodejs GHA2DB_LOCAL=1 structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql nodejs -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_PROJECT=nodejs PG_DB=nodejs GHA2DB_LOCAL=1 ./gha2db 2018-04-01 0 today now 'nodejs' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=nodejs PG_DB=nodejs GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=nodejs PG_DB=nodejs ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 4
