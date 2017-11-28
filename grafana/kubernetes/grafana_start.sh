#!/bin/sh
cd /usr/share/grafana.k8s
grafana-server -config /etc/grafana.k8s/grafana.ini cfg:default.paths.data=/var/lib/grafana.k8s 1>/var/log/grafana.k8s.log 2>&1
