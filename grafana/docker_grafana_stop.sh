#!/bin/sh
docker stop `docker ps | grep 'grafana/grafana' | cut -f 1 -d ' '`
