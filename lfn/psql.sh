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
GHA2DB_PROJECT=lfn PG_DB=lfn GHA2DB_LOCAL=1 ./structure 2>>errors.txt | tee -a run.log || exit 1
./devel/db.sh psql lfn -c "create extension if not exists pgcrypto" || exit 1
./devel/ro_user_grants.sh lfn || exit 2
# GHA2DB_PROJECT=lfn PG_DB=lfn GHA2DB_LOCAL=1 ./gha2db 2018-11-25 0 today now 'iovisor,mininet,opennetworkinglab,opensecuritycontroller,open-switch,p4lang,OpenBMP,tungstenfabric,opencord' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=lfn PG_DB=lfn GHA2DB_LOCAL=1 ./gha2db 2015-01-01 0 today now 'iovisor,mininet,opennetworkinglab,opensecuritycontroller,open-switch,p4lang,OpenBMP,tungstenfabric,opencord' 2>>errors.txt | tee -a run.log || exit 3
GHA2DB_PROJECT=lfn PG_DB=lfn GHA2DB_LOCAL=1 GHA2DB_OLDFMT=1 ./gha2db 2014-01-01 0 2014-12-31 23 'iovisor,mininet,opennetworkinglab,opensecuritycontroller,open-switch,p4lang,OpenBMP,tungstenfabric,opencord' 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=lfn PG_DB=lfn GHA2DB_LOCAL=1 GHA2DB_MGETC=y GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 ./structure 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=lfn PG_DB=lfn ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 6
GHA2DB_PROJECT=lfn PG_DB=lfn ./shared/setup_scripts.sh 2>>errors.txt | tee -a run.log || exit 7
GHA2DB_PROJECT=lfn PG_DB=lfn ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 8
GHA2DB_PROJECT=lfn PG_DB=lfn ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 9
GHA2DB_PROJECT=lfn PG_DB=lfn GHA2DB_LOCAL=1 GHA2DB_EXCLUDE_VARS="projects_health_partial_html" ./vars || exit 10
