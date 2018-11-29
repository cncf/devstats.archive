#!/bin/bash
./docker/docker_make_mount_dirs.sh
docker run --mount src="/data/psql",target="/var/lib/postgresql/data",type=bind -it postgres:11 /bin/bash
