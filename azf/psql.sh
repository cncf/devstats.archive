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
GHA2DB_PROJECT=azf PG_DB=azf GHA2DB_LOCAL=1 structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql azf -c "create extension if not exists pgcrypto" || exit 1
GHA2DB_PROJECT=azf PG_DB=azf GHA2DB_LOCAL=1 gha2db 2015-04-27 0 today now 'Azure/Azure-Functions,Azure/azure-functions-host,Azure/azure-webjobs-sdk,Azure/azure-webjobs-sdk-extensions,Azure/azure-functions-durable-extension,Azure/azure-functions-durable-js,Azure/azure-functions-core-tools,Azure/azure-functions-nodejs-worker,Azure/azure-functions-java-worker,Azure/azure-functions-python-worker,Azure/azure-functions-ux,Azure/azure-functions-templates,Azure/azure-webjobs-sdk-script-samples,Azure/azure-functions-vs-build-sdk,Azure/azure-webjobs-sdk-script,Azure/azure-webjobs-sdk-templates,Azure/azure-functions-cli,projectkudu/AzureFunctions,projectkudu/WebJobsPortal,projectkudu/AzureFunctionsPortal,projectkudu/azure-functions-ux' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=azf PG_DB=azf GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 structure 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=azf PG_DB=azf ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=azf PG_DB=azf ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=azf PG_DB=azf ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=azf PG_DB=azf ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=azf PG_DB=azf GHA2DB_LOCAL=1 vars || exit 8
./devel/ro_user_grants.sh azf || exit 9
./devel/psql_user_grants.sh devstats_team azf || exit 10
