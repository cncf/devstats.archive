#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
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
    if [ $proj = "kubernetes" ]
    then
      db="gha"
    elif [ $proj = "all" ]
    then
      db="allprj"
    fi
    echo "Project: $proj, PDB: $db"
    sudo -u postgres psql "$db" -c "insert into gha_postprocess_scripts(ord, path) select 0, 'scripts/$proj/repo_groups.sql' on conflict do nothing" || exit 1
done
echo 'OK'
