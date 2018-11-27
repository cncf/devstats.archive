#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
docker run -e POSTGRES_PASSWORD="${PG_PASS}" -p 65432:5432 postgres:11 1>/tmp/docker.psql.log 2>/tmp/docker.psql.err &
