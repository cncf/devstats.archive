#!/bin/bash
# SKIPDEL=1 - skip delete current vars
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
    if [ -z "${SKIPDEL}" ]
    then
      ./devel/db.sh psql "$db" -c "delete from gha_vars" || exit 1
    fi
    GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db ./vars || exit 2
    GHA2DB_LOCAL=1 GHA2DB_PROJECT=$proj PG_DB=$db GHA2DB_VARS_FN_YAML="sync_vars.yaml" ./vars || exit 3
done
echo 'OK'
