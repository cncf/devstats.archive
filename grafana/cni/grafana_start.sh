#!/bin/sh
cd /usr/share/grafana.cni
grafana-server -config /etc/grafana.cni/grafana.ini cfg:default.paths.data=/var/lib/grafana.cni 1>/var/log/grafana.cni.log 2>&1
