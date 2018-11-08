#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
set -o pipefail
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
> errors.txt
> run.log
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" nats -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 ./gha2db 2015-01-01 0 today now 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./gha2db 2014-01-02 0 2014-03-02 16 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_EXACT=1 GHA2DB_OLDFMT=1 ./gha2db 2014-03-02 18 2014-12-31 23 'nats-io,apcera/nats,apcera/gnatsd' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=nats PG_DB=nats ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=nats PG_DB=nats ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=nats PG_DB=nats ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=nats PG_DB=nats ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 8
GHA2DB_PROJECT=nats PG_DB=nats GHA2DB_LOCAL=1 ./vars || exit 9
./devel/ro_user_grants.sh nats || exit 10
./devel/psql_user_grants.sh devstats_team nats || exit 11
