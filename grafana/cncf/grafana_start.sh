#!/bin/sh
cd /usr/share/grafana.cncf
grafana-server -config /etc/grafana.cncf/grafana.ini cfg:default.paths.data=/var/lib/grafana.cncf 1>/var/log/grafana.cncf.log 2>&1
