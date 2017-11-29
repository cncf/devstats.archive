#!/bin/sh
cd /usr/share/grafana.grpc
grafana-server -config /etc/grafana.grpc/grafana.ini cfg:default.paths.data=/var/lib/grafana.grpc 1>/var/log/grafana.grpc.log 2>&1
