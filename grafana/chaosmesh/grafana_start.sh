#!/bin/bash
cd /usr/share/grafana.chaosmesh
grafana-server -config /etc/grafana.chaosmesh/grafana.ini cfg:default.paths.data=/var/lib/grafana.chaosmesh 1>/var/log/grafana.chaosmesh.log 2>&1
