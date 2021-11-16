#!/bin/bash
cd /usr/share/grafana.dapr
grafana-server -config /etc/grafana.dapr/grafana.ini cfg:default.paths.data=/var/lib/grafana.dapr 1>/var/log/grafana.dapr.log 2>&1
