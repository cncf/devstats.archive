#!/bin/bash
if [ -z "${PG_PASS}" ]
then
    echo "You need to set PG_PASS environment variable to run this script (needs RO access)"
  exit 1
fi
if [ -z "${GHA2DB_ES_URL}" ]
then
  echo "You need to set GHA2DB_ES_URL environment variable to run this script"
  exit 2
fi
. ./devel/all_projs.sh || exit 3
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
    ./$proj/reinit_es_only.sh || exit 4
  else
    GHA2DB_PROJECT=$proj PG_DB=$db ./shared/reinit_es_only.sh || exit 5
  fi
done
GHA2DB_USE_ES=1 GHA2DB_USE_ES_ONLY=1 GHA2DB_SKIPTSDB=1 GHA2DB_SKIPPDB=1 GHA2DB_LOCAL=1 ./devstats
