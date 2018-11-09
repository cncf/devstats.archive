#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
./devel/drop_psql_db.sh gha &&\
./kubernetes/psql.sh &&\
./devel/restore_artificial.sh gha &&\
./devel/db.sh psql gha -f util_sql/current_state_all.sql &&\
./devel/db.sh psql gha -f ./util_sql/current_state_grants.sql &&\
./util_sh/refresh_mviews.sh &&\
ONLY=kubernetes SKIPTEMP=1 ./devel/reinit.sh &&\
ONLY=kubernetes ./devel/vars_all.sh &&\
ONLY=gha cron/cron_db_backup_all.sh
