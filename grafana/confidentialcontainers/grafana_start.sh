#!/bin/bash
cd /usr/share/grafana.confidentialcontainers
grafana-server -config /etc/grafana.confidentialcontainers/grafana.ini cfg:default.paths.data=/var/lib/grafana.confidentialcontainers 1>/var/log/grafana.confidentialcontainers.log 2>&1
