#!/bin/bash
if [ -z "${PG_PASS}" ]
then
  echo "You need to set PG_PASS environment variable to run this script"
  exit 1
fi
./docker/docker_make_mount_dirs.sh
docker run --shm-size=1g --mount src="/data/psql",target="/var/lib/postgresql/data",type=bind -e POSTGRES_PASSWORD="${PG_PASS}" -p 65432:5432 postgres:11 1>/tmp/docker.psql.log 2>/tmp/docker.psql.err &

