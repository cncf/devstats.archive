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
    if [ $proj = "kubernetes" ]
    then
      db="gha"
    elif [ $proj = "all" ]
    then
      db="allprj"
    fi
    echo "Project: $proj, PDB: $db"
    ./devel/db.sh psql "$db" -c "insert into gha_postprocess_scripts(ord, path) select 0, 'scripts/$proj/repo_groups.sql' on conflict do nothing" || exit 1
done
echo 'OK'
