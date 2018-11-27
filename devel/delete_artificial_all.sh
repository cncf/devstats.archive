#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
. ./devel/all_dbs.sh || exit 2
for db in $all
do
 PG_DB=$db ./devel/delete_artificial.sh
done
echo 'All artificial events deleted'
