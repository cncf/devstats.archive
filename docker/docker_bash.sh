#!/bin/bash
./docker/docker_make_mount_dirs.sh
docker run --mount src="/data/devstats",target="/root",type=bind -it devstats /bin/bash
