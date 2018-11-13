#!/bin/bash
# DBDEBUG=1 - verbose operations
if [ -z "$PG_PASS" ]
then
  echo "$0: you need to set PG_PASS=... $*"
  exit 1
fi
if [ -z "$1" ]
then
  echo "$0 you need to specify at least one argument"
  exit 2
fi
if [ -z "$PG_HOST" ]
then
  PG_HOST=127.0.0.1
fi
if [ -z "$PG_PORT" ]
then
  PG_PORT=5432
fi
if [ -z "$PG_USER" ]
then
  PG_USER=postgres
fi
cmd=${1}
shift
if [ ! -z "$DBDEBUG" ]
then
  echo "PGPASSWORD=... '${cmd}' -U '${PG_USER}' -h '${PG_HOST}' -p '${PG_PORT}' '${@}'"
fi
PGPASSWORD="${PG_PASS}" "${cmd}" -U "${PG_USER}" -h "${PG_HOST}" -p "${PG_PORT}" "${@}"
