#!/bin/sh
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
./devel/drop_psql_db.sh temp &&\
GHA2DB_LOCAL=1 PG_DB=temp ./structure &&\
GHA2DB_LOCAL=1 PG_DB=temp GHA2DB_SKIPTABLE=1 GHA2DB_INDEX=1 GHA2DB_MGETC=y ./structure &&\
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" temp -f util_sql/current_state_all.sql &&\
sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" temp -f util_sql/current_state_grants.sql &&\
#sudo -u postgres pg_dump -s temp > structure.sql &&\
sudo -u postgres pg_dump temp > structure.sql &&\
./devel/drop_psql_db.sh temp && echo 'structure.sql generated'
