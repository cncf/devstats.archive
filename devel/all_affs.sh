#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi

function finish {
    sync_unlock.sh
    rm -f /tmp/deploy.wip 2>/dev/null
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
  > /tmp/deploy.wip
fi

GHA2DB_LOCAL=1 GHA2DB_PROCESS_REPOS=1 ./get_repos

if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "cncftest.io" ]
  then
    all=`cat ./devel/all_test_projects.txt`
  else
    all=`cat ./devel/all_prod_projects.txt`
  fi
else
  all=$ONLY
fi

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
  if [ -f "./$proj/import_affs.sh" ]
  then
    ./$proj/import_affs.sh || exit 1
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/import_affs.sh || exit 2
  fi
  if [ -f "./$proj/update_affs.sh" ]
  then
    ./$proj/update_affs.sh || exit 3
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/update_affs.sh || exit 4
  fi
done
echo 'All affiliations updated'
