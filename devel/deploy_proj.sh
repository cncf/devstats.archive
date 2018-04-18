#!/bin/bash
# GET=1 (attempt to fetch Postgres database and Grafana database from the test server)
# IGET=1 (attempt to fetch Influx database from the test server)
# AGET=1 (attempt to fetch 'All CNCF' Postgres database from the test server)
# SKIPDBS=1 (entirely skip project's databases operations: Influx and Postgres)
# SKIPADDALL=1 (skip adding/merging to allprj)
# SKIPGRAFANA=1 (skip all grafana related stuff)
set -o pipefail
if ( [ -z "$PG_PASS" ] || [ -z "$IDB_PASS" ] || [ -z "$IDB_HOST" ] )
then
  echo "$0: You need to set PG_PASS, IDB_PASS, IDB_HOST environment variables to run this script"
  exit 1
fi
if ( [ ! -z "$IGET" ] && [ -z "$IDB_PASS_SRC" ] )
then
  echo "$0: You need to set IDB_PASS_SRC environment variable when using IGET"
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
echo "$0: $PROJ deploy started"
if [ -z "$SKIPDBS" ]
then
  PDB=1 IDB=1 ./devel/create_databases.sh || exit 3
fi
if ( [ -z "$SKIPADDALL"] && [ ! "$PROJ" = "all" ] && [ ! "$PROJ" = "opencontainers" ] )
then
  IDB=1 ./all/add_project.sh "$PROJDB" "$PROJREPO" || exit 4
fi
if [ -z "$SKIPGRAFANA" ]
then
  ./devel/create_grafana.sh || exit 5
fi
echo "$0: $PROJ deploy finished"
