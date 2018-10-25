#!/bin/bash
if [ -z "$PG_PASS" ]
then
  echo "$0: PG_PASS environment variable must be set"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0: please specify date from YYYY-MM-DD as a first argument"
  exit 2
fi
if [ -z "$2" ]
then
  echo "$0: please specify hour from HH as a second argument"
  exit 3
fi
# GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 GHA2DB_USE_ES=1 GHA2DB_PROJECT=cncf PG_DB=cncf ./gha2es 2018-06-01 4 today now
GHA2DB_DEBUG=1 GHA2DB_LOCAL=1 GHA2DB_USE_ES=1 GHA2DB_PROJECT=all PG_DB=allprj ./gha2es "$1" "$2" today now
