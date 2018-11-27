#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: PG_PASS environment variable must be set"
  exit 1
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
  if [ -f "./$proj/annotations.sh" ]
  then
    echo "Adding annotations data for project: $proj, db: $db (using project specific script)"
    ./$proj/annotations.sh
  else
    echo "Adding annotations data for project: $proj, db: $db (using shared script)"
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/annotations.sh
  fi
done
echo 'OK'
