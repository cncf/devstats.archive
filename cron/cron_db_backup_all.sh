#!/bin/bash
if [ ! -z "${NOBACKUP}" ]
then
  exit 0
fi
LIST_FN_PREFIX="/etc/gha2db/all_" . all_dbs.sh || exit 2
for proj in $all
do
  cron_db_backup.sh "$proj" 2>> "/tmp/gha2db_backup_$proj.err" 1>> "/tmp/gha2db_backup_$proj.log"
done
