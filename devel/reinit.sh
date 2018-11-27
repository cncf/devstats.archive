#!/bin/bash
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

GHA2DB_LOCAL=1 GHA2DB_PROCESS_REPOS=1 ./get_repos

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
  if [ -f "./$proj/reinit.sh" ]
  then
    ./$proj/reinit.sh || exit 1
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/reinit.sh || exit 2
  fi
done
