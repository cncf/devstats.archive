#!/bin/bash
# docker run -p 19200:9200 -p 19300:9300 -e ES_JAVA_OPTS="-Xms2g -Xmx2g" --ulimit nofile=65536:65536 elasticsearch:6.5.1 1>/tmp/docker.es.log 2>/tmp/docker.es.err &
./docker/docker_make_mount_dirs.sh
docker run --mount src="/data/es",target="/usr/share/elasticsearch/data",type=bind -p 19200:9200 -p 19300:9300 --ulimit nofile=65536:65536 elasticsearch:6.5.1 1>/tmp/docker.es.log 2>/tmp/docker.es.err &
