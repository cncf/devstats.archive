#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "$GHA2DB_ES_URL" ]
then
  echo "$0: you need to set GHA2DB_ES_URL=..."
  exit 2
fi

export TRAP=1

. ./devel/all_projs.sh || exit 3

for proj in $all
do
  db=$proj
  if [ "$db" = "kubernetes" ]
  then
    db="gha"
  elif [ "$db" = "all" ]
  then
    db="allprj"
  fi
  # Also consider: GHA2DB_RESET_ES_RAW=1, GHA2DB_USE_ES_RAW=1
  GHA2DB_SKIPTSDB=1 GHA2DB_USE_ES_ONLY=1 GHA2DB_USE_ES=1 GHA2DB_PROJECT=$proj PG_DB=$db ./devel/add_single_metric.sh || exit 4
  GHA2DB_SKIPTSDB=1 GHA2DB_USE_ES_ONLY=1 GHA2DB_USE_ES=1 GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db ./vars || exit 5
done

echo 'OK'
