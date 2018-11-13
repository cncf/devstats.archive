#!/bin/bash
if ( [ -z "$PG_PASS" ] || [ -z "$PG_PASS_RO" ] || [ -z "$PG_PASS_TEAM" ] )
then
  echo "$0: you need to set PG_PASS=... PG_PASS_RO=... PG_PASS_TEAM=... environment variables"
  exit 1
fi
INIT=1 GHA2DB_GHAPISKIP=1 SKIPTEMP=1 NOLOCK=1 SKIPADDALL=1 NOBACKUP=1 PG_HOST=127.0.0.1 PG_PORT=65432 ./docker/docker_deploy_all.sh
