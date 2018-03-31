#!/bin/bash
if ( [ -z "$PROJ" ] || [ -z "$PROJDB" ] || [ -z "$IDB_PASS" ] )
then
  echo "$0: you need to set PROJ, PROJDB and IDB_PASS env variables to use this script"
  exit 1
fi
echo "To clear old annotations use: 'influx -host 127.0.0.1 -username gha_admin -password ... -database $PROJDB', then 'drop series from annotations; drop series from quick_ranges; drop series from computed;'"
GHA2DB_PROJECT=$PROJ GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 PG_DB=$PROJDB IDB_DB=$PROJDB ./annotations
