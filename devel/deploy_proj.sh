#!/bin/bash
set -o pipefail
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 1
fi
if ( [ -z "$PROJ" ] || [ -z "$PROJDB" ] || [ -z "$PROJREPO" ] || [ -z "$PORT" ] || [ -z "$GA" ] || [ -z "$ICON" ] || [ -z "$ORGNAME" ] || [ -z "$GRAFSUFF" ] )
then
  echo "$0: You need to set PROJ, PROJDB, PROJREPO, PORT, GA, ICON, ORGNAME, GRAFSUFF environment variables to run this script"
  exit 2
fi
function finish {
    sync_unlock.sh
    rm -f /tmp/deploy.wip 2>/dev/null
}
if [ -z "$TRAP" ]
then
  sync_lock.sh || exit -1
  trap finish EXIT
  export TRAP=1
  > /tmp/deploy.wip
fi
PDB=1 GET=1 IDB=1 ./devel/create_databases.sh || exit 3
if [ ! "$PROJ" = "all" ]
then
  IDB=1 ./all/add_project.sh "$PROJDB" "$PROJREPO" || exit 4
fi
GET=1 CERT=1 ./devel/create_grafana.sh || exit 5
./devel/create_www.sh || exit 6
echo "$PROJ deploy finished"
