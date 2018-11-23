#!/bin/bash
docker run -p 19200:9200 -p 19300:9300 elasticsearch:6.5.1 1>/tmp/docker.es.log 2>/tmp/docker.es.err &
