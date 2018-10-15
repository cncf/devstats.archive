#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "$0: you need to specify PG_PASS=... $0 $*"
  exit 1
fi
FROM="2018-10-15" REPO="cncf/devstats" GHA2DB_DEBUG=1 GHA2DB_GHAPISKIPEVENTS=1 PG_DB=cncf ./ghapi2db
# REPO="cncf/devstats" GHA2DB_DEBUG=1 GHA2DB_GHAPISKIPEVENTS=1 GHA2DB_QOUT=1 PG_DB=cncf ./ghapi2db
