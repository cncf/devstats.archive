#!/bin/sh
cd /usr/share/grafana.vitess
grafana-server -config /etc/grafana.vitess/grafana.ini cfg:default.paths.data=/var/lib/grafana.vitess 1>/var/log/grafana.vitess.log 2>&1
