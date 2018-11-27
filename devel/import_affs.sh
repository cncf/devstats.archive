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
  if [ -f "./$proj/import_affs.sh" ]
  then
    ./$proj/import_affs.sh || exit 1
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/import_affs.sh || exit 2
  fi
done
echo 'OK'
