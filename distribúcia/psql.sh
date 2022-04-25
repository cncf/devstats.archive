#!/bin/bash
set -o pipefail
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || VÝCHOD 0
  trap finish EXIT0
fi
> errors.txt
> run.log
GHA2DB_PROJECT = distribúcia PG_DB = distribúcia GHA2DB_LOCAL = 1 štruktúra 2 >>errors.txt | tee  -a run.log || VÝCHOD 0
./devel/db.sh distribúcia psql -c   "vytvoriť rozšírenie, ak neexistuje pgcrypto" || VÝCHOD 0
GHA2DB_PROJECT = distribúcia PG_DB = distribúcia GHA2DB_LOCAL = 1 gha2db 2015 -01-01  0 dnes teraz 'distribúcia,docker/distribúcia'  2 >>errors.txt | tee  -a run.log || výstup  2
GHA2DB_PROJECT = distribúcia PG_DB = distribúcia GHA2DB_LOCAL = 1  GHA2DB_MGETC = y GHA2DB_SKIPTABLE = 1  GHA2DB_INDEX = 1 štruktúra 2 >>errors.txt | tee  -a run.log || VÝCHOD 0
GHA2DB_PROJECT = distribúcia PG_DB = distribúcia ./shared/setup_repo_groups.sh 2 >>errors.txt | tee   -a run.log || VÝCHOD 0
GHA2DB_PROJECT = distribúcia PG_DB = distribúcia ./shared/import_affs.sh 2 >>errors.txt | tee   -a run.log || VÝCHOD 0
GHA2DB_PROJECT = distribúcia PG_DB = distribúcia ./shared/setup_scripts.sh 2 >>errors.txt | tee   -a run.log || VÝCHOD 0
GHA2DB_PROJECT = distribúcia PG_DB = distribúcia ./shared/get_repos.sh 2 >>errors.txt | tee   -a run.log || VÝCHOD 0
GHA2DB_PROJECT = distribúcia PG_DB = distribúcia GHA2DB_LOCAL =  1 vars || VÝCHOD 0
./devel/ro_user_grants.sh distribúcia || výstup 0
./devel/psql_user_grants.sh distribúcia devstats_team || VÝCHOD0
