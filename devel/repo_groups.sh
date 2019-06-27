#!/bin/bash
# ALL_REPOS=1 (run get_repos on all repos prior to setup)
# REPOS=1 (run full commits analysis get_repos on each project  after setting up new repo groups)
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
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
if [ ! -z "$ALL_REPOS" ]
then
  GHA2DB_LOCAL=1 GHA2DB_PROCESS_REPOS=1 get_repos
fi
. ./devel/all_projs.sh || exit 2
for proj in $all
do
  db=$proj
  if [ "$proj" = "kubernetes" ]
  then
    db="gha"
  elif [ "$proj" = "all" ]
  then
    db="allprj"
  fi
  echo "Project: $proj, PDB: $db"
  GHA2DB_PROJECT=$proj PG_DB=$db ./shared/setup_repo_groups.sh || exit 3
  if [ ! -z "$REPOS" ]
  then
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/get_repos.sh || exit 4
  fi
done
echo 'OK'
