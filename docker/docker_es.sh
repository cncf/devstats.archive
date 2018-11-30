#!/bin/bash
./docker/docker_make_mount_dirs.sh
# ES_HEAP_SIZE=10g
docker run --mount src="/data/es",target="/usr/share/elasticsearch/data",type=bind -p 19200:9200 -p 19300:9300 --ulimit nofile=65536:65536 -e ES_JAVA_OPTS="-Xms4g -Xmx4g" elasticsearch:6.5.1 1>/tmp/docker.es.log 2>/tmp/docker.es.err &
