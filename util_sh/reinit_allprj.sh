#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
./devel/drop_psql_db.sh allprj &&\
./all/psql.sh &&\
ONLY=all SKIPTEMP=1 ./devel/reinit.sh &&\
ONLY=all ./devel/vars_all.sh &&\
ONLY=allprj cron/cron_db_backup_all.sh
