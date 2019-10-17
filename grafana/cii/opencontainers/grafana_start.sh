#!/bin/bash
cd /usr/share/grafana.opencontainers
grafana-server -config /etc/grafana.opencontainers/grafana.ini cfg:default.paths.data=/var/lib/grafana.opencontainers 1>/var/log/grafana.opencontainers.log 2>&1
