#!/bin/bash
if [ ! -z "${NOBACKUP}" ]
then
  exit 0
fi
if [ -z "$GHA2DB_DATADIR" ]
then
  GHA2DB_DATADIR=/etc/gha2db
fi
LIST_FN_PREFIX="${GHA2DB_DATADIR}/all_" . all_dbs.sh || exit 2
for proj in $all
do
  cron_db_backup.sh "$proj" 2>> "/tmp/gha2db_backup_$proj.err" 1>> "/tmp/gha2db_backup_$proj.log"
done
