#!/bin/bash
# DROP=1 (will drop DB)
# GET=1 (will use DB backup if available)
set -o pipefail
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 1
fi
function finish {
    rm -rf nats.dump >/dev/null 2>&1
    sync_unlock.sh
}
trap finish EXIT
sync_lock.sh || exit -1
exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = 'nats'"` || exit 1
if ( [ ! -z "$DROP" ] && [ "$exists" = "1" ] )
then
  echo 'dropping database nats'
  sudo -u postgres psql -c 'drop database nats' || exit 2
fi
exists=`sudo -u postgres psql -tAc "select 1 from pg_database WHERE datname = 'nats'"` || exit 3
if [ ! "$exists" = "1" ]
then
  echo 'creating database nats'
  sudo -u postgres psql -c 'create database nats' || exit 4
  sudo -u postgres psql -c 'grant all privileges on database "nats" to gha_admin' || exit 5
  if [ ! -z "$GET" ]
  then
    echo 'attempt to fetch database from backup'
    wget https://cncftest.io/nats.dump || exit 6
    sudo -u postgres pg_restore -d nats nats.dump || exit 7
    rm -f nats.dump || exit 8
  else
    echo 'generating database'
  fi
else
  echo 'nats database already exists'
fi
