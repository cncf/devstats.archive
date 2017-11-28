#!/bin/sh
cd /usr/share/grafana.fluentd
grafana-server -config /etc/grafana.fluentd/grafana.ini cfg:default.paths.data=/var/lib/grafana.fluentd 1>/var/log/grafana.fluentd.log 2>&1
