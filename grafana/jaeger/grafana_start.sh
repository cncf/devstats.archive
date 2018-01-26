#!/bin/sh
cd /usr/share/grafana.jaeger
grafana-server -config /etc/grafana.jaeger/grafana.ini cfg:default.paths.data=/var/lib/grafana.jaeger 1>/var/log/grafana.jaeger.log 2>&1
