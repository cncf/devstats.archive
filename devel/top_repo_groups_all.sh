#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
. ./devel/all_projs.sh || exit 2
for f in $all
do
    db=$f
    if [ $f = "kubernetes" ]
    then
      db="gha"
    elif [ $f = "all" ]
    then
      db="allprj"
    fi
    echo "$f -> $db"
    if [ -f "./$f/top_n_repos_groups.sh" ]
    then
      ./$f/top_n_repos_groups.sh 70 >> ./metrics/$f/gaps.yaml || exit 1
    else
      GHA2DB_PROJECT=$f PG_DB=$db ./shared/top_n_repos_groups.sh 70 >> ./metrics/$f/gaps.yaml || exit 1
    fi
done
echo 'OK'
