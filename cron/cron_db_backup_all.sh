#!/bin/bash
if [ ! -z "${NOBACKUP}" ]
then
  exit 0
fi
if [ -z "$ONLY" ]
then
  host=`hostname`
  if [ $host = "teststats.cncf.io" ]
  then
    all=`cat /etc/gha2db/all_test_dbs.txt`
  else
    all=`cat /etc/gha2db/all_prod_dbs.txt`
  fi
  all="${all} devstats"
else
  all=$ONLY
fi
for proj in $all
do
  cron_db_backup.sh "$proj" 2>> "/tmp/gha2db_backup_$proj.err" 1>> "/tmp/gha2db_backup_$proj.log"
done
