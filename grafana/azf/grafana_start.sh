#!/bin/bash
cd /usr/share/grafana.azf
grafana-server -config /etc/grafana.azf/grafana.ini cfg:default.paths.data=/var/lib/grafana.azf 1>/var/log/grafana.azf.log 2>&1
