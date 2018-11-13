#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
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
# service postgresql restart || exit 3
systemctl restart postgresql@10-main || exit 3
echo -n "waiting for postgres to respond..."
while true
do
  exists=`db.sh psql -tAc "select 1 from pg_database WHERE datname = 'devstats'"`
  if [ "$exists" = "1" ]
  then
    break
  fi
  sleep 1
  echo -n "."
done
echo "ok"
