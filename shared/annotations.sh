#!/bin/bash
if ( [ -z "$GHA2DB_PROJECT" ] || [ -z "$IDB_DB" ] || [ -z "$IDB_PASS" ] )
then
  echo "$0: you need to set GHA2DB_PROJECT, IDB_DB and IDB_PASS env variables to use this script"
  exit 1
fi
echo "To clear old annotations use: 'influx -host 127.0.0.1 -username gha_admin -password ... -database $IDB_DB', then 'drop series from annotations; drop series from quick_ranges; drop series from computed;'"
GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 ./annotations
