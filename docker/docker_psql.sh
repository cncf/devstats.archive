#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
mkdir /data 2>/dev/null
mkdir /data/psql 2>/dev/null
docker run --mount src="/data/psql",target="/var/lib/postgresql",type=bind -e POSTGRES_PASSWORD="${PG_PASS}" -p 65432:5432 postgres:11 1>/tmp/docker.psql.log 2>/tmp/docker.psql.err &

