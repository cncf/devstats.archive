#!/bin/bash
cd /usr/share/grafana.keda
grafana-server -config /etc/grafana.keda/grafana.ini cfg:default.paths.data=/var/lib/grafana.keda 1>/var/log/grafana.keda.log 2>&1
