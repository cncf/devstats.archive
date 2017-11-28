#!/bin/sh
cd /usr/share/grafana.opentracing
grafana-server -config /etc/grafana.opentracing/grafana.ini cfg:default.paths.data=/var/lib/grafana.opentracing 1>/var/log/grafana.opentracing.log 2>&1
