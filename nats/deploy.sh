#!/bin/bash
set -o pipefail
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 1
fi
function finish {
    sync_unlock.sh
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
fi
proj=nats
projdb=nats
projorg=nats-io
PDB=1 GET=1 IDB=1 ./$proj/create_databases.sh || exit 2
IDB=1 ./all/add_project.sh "$projdb" "$projorg" || exit 3
GET=1 STOP=1 CERT=1 ./$proj/create_grafana.sh || exit 4
echo 'Deploy finished'
