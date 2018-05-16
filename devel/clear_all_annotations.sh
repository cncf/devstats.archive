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
    echo "Clearing annotations data on $db"
    sudo -u postgres psql -c "delete from sannotations" || exit 1
    sudo -u postgres psql -c "delete from tquick_ranges" || exit 1
    sudo -u postgres psql -c "delete from gha_computed" || exit 1
done
echo 'OK'
