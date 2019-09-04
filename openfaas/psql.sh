#!/bin/bash
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
GHA2DB_PROJECT=openfaas PG_DB=openfaas GHA2DB_LOCAL=1 structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql openfaas -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_PROJECT=openfaas PG_DB=openfaas GHA2DB_LOCAL=1 gha2db 2016-12-22 0 today now 'openfaas,open-faas,stefanprodan/caddy-builder,alexellis/faas,alexellis/faas-cli,alexellis/java-afterburn,alexellis/faas-netes,alexellis/caddy-builder,alexellis/openfaas-workshop,alexellis/derek,alexellis/java-openfaas-fast-fork,alexellis/openfaas-cloud,alexellis/faas-nats,alexellis/serverless-faas,alexellis/faas-provider,alexellis/nodejs-afterburn' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=openfaas PG_DB=openfaas GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=openfaas PG_DB=openfaas ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=openfaas PG_DB=openfaas ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=openfaas PG_DB=openfaas ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=openfaas PG_DB=openfaas ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=openfaas PG_DB=openfaas GHA2DB_LOCAL=1 vars || exit 8
./devel/ro_user_grants.sh openfaas || exit 9
./devel/psql_user_grants.sh devstats_team openfaas || exit 10
