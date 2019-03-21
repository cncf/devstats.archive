#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
./devel/drop_psql_db.sh temp &&\
GHA2DB_LOCAL=1 PG_DB=temp structure &&\
GHA2DB_LOCAL=1 PG_DB=temp GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 GHA2DB_MGETC=y structure &&\
./devel/db.sh psql temp -f util_sql/current_state_all.sql &&\
./devel/db.sh psql temp -f util_sql/current_state_grants.sql &&\
#./devel/db.sh pg_dump -s temp > structure.sql &&\
./devel/db.sh pg_dump temp > structure.sql &&\
./devel/drop_psql_db.sh temp && echo 'structure.sql generated'
