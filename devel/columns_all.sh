#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
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
  echo "Project: $proj, PDB: $db"
  GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db columns || exit 2
done
echo 'OK'
