#!/bin/bash
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "cncftest.io" ]
  then
    all=`cat ./devel/all_test_dbs.txt`
  else
    all=`cat ./devel/all_prod_dbs.txt`
  fi
else
  all=$ONLY
fi
for db in $all
do
    echo "wget $db.sql.xz"
    rm -f $db.sql.xz 2>/dev/null
    rm -f $db.sql 2>/dev/null
    wget https://cncftest.io/$db.sql.xz || exit 1
    ls -l $db.sql.xz
    echo "xz -d $db.sql"
    xz -d $db.sql.xz || exit 2
    echo "restore $db"
    ls -l $db.sql
    sudo -u postgres psql -c "drop database $db" 2> /dev/null
    sudo -u postgres psql -c "create database $db" || exit 3
    sudo -u postgres psql $db < $db.sql || exit 4
    echo "rm -f $db"
    rm -f $proj.db || exit 5
    proj=$db
    if [ "$db" = "gha" ]
    then
      proj="kubernetes"
    elif [ "$db" = "allprj" ]
    then
      proj="all"
    fi
    echo "Project: $proj, PDB: $db"
    GHA2DB_PROJECT="$proj" PG_DB="$db" GHA2DB_LOCAL=1 ./vars || exit 6
done
echo 'OK'
