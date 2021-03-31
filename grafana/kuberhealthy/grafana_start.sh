#!/bin/bash
cd /usr/share/grafana.kuberhealthy
grafana-server -config /etc/grafana.kuberhealthy/grafana.ini cfg:default.paths.data=/var/lib/grafana.kuberhealthy 1>/var/log/grafana.kuberhealthy.log 2>&1
