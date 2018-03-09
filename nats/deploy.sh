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
trap finish EXIT
sync_lock.sh || exit -1
proj=nats
PDB=1 GET=1 IDB=1 ./$proj/create_databases.sh || exit 1
IDB=1 ./all/add_project.sh "$proj" || exit 2
./$proj/create_grafana.sh || exit 3
echo 'OK'
