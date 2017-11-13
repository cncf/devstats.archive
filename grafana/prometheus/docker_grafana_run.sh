#!/bin/sh
docker run --name prometheus_grafana -d -p 3001:3000 -v /var/lib/grafana.prometheus:/var/lib/grafana -v /etc/grafana.prometheus:/etc/grafana -v /usr/share/grafana.prometheus:/usr/share/grafana grafana/grafana:master
