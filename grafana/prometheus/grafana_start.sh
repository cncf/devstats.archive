#!/bin/sh
cd /usr/share/grafana.prometheus
grafana-server -config /etc/grafana.prometheus/grafana.ini cfg:default.paths.data=/var/lib/grafana.prometheus 1>/var/log/grafana.prometheus.log 2>&1
