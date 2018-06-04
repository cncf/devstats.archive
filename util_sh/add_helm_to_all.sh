#!/bin/bash
GHA2DB_PROJECT=all PG_DB=helm GHA2DB_LOCAL=1 ./gha2db 2015-10-06 0 today now 'helm' 2>>errors.txt | tee -a run.log || exit 2
GHA2DB_PROJECT=all PG_DB=helm ./shared/setup_repo_groups.sh 2>>errors.txt | tee -a run.log || exit 4
GHA2DB_PROJECT=all PG_DB=helm ./shared/import_affs.sh 2>>errors.txt | tee -a run.log || exit 5
GHA2DB_PROJECT=all PG_DB=helm ./shared/get_repos.sh 2>>errors.txt | tee -a run.log || exit 7
