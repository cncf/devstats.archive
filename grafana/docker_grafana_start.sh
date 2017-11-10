#!/bin/sh
docker run -d -p 2222:22 -p 3001:3000 -v /var/lib/grafana.prometheus:/var/lib/grafana -v /etc/grafana.prometheus:/etc/grafana grafana/grafana:master
