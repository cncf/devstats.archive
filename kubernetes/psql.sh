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
GHA2DB_PROJECT=kubernetes PG_DB=gha IDB_DB=gha GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
# Next 4 calls takes about: 1+2=2h, 3=26m, 4=17m
GHA2DB_PROJECT=kubernetes PG_DB=gha IDB_DB=gha GHA2DB_LOCAL=1 ./gha2db 2015-08-06 0 today now 'kubernetes,kubernetes-client,kubernetes-incubator,kubernetes-helm' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=kubernetes PG_DB=gha IDB_DB=gha GHA2DB_LOCAL=1 GHA2DB_EXACT=1 ./gha2db 2015-01-01 0 2015-08-14 0 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=kubernetes PG_DB=gha IDB_DB=gha GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 GHA2DB_EXACT=1 ./gha2db 2014-06-02 0 2014-12-31 23 'GoogleCloudPlatform/kubernetes,kubernetes,kubernetes-client' 2>>errors.txt | tee -a run.log || exit 4
# This generates index and summary tables, it takes 5m32s
GHA2DB_PROJECT=kubernetes PG_DB=gha IDB_DB=gha GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 5
./kubernetes/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 7
./kubernetes/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 8
# This imports affiliations from cncf/gitdm:github_users.json
./import_affs github_users.json 2>>errors.txt | tee -a run.log || exit 6
./kubernetes/get_repos.sh 2>>errors.txt | tee -a run.log || exit 9
echo "All done. You should run ./kubernetes/reinit_all_full.sh script now."
