#!/bin/bash
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi

if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
function finish {
  rm -rf "$PROJDB.dump" >/dev/null 2>&1
  sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
echo "restarting postgresql"
service postgresql restart || exit 3
echo -n "waiting for postgres to respond..."
while true
do
  exists=`sudo -u postgres psql -h "$PG_HOST" -p "$PG_PORT" -tAc "select 1 from pg_database WHERE datname = 'devstats'"`
  if [ "$exists" = "1" ]
  then
    break
  fi
  sleep 1
  echo -n "."
done
echo "ok"
