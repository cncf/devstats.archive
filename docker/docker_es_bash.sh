#!/bin/bash
./docker/docker_make_mount_dirs.sh
docker run --mount src="/data/es",target="/usr/share/elasticsearch/data",type=bind -it elasticsearch:6.5.1 /bin/bash
