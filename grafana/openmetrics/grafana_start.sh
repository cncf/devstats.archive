#!/bin/bash
cd /usr/share/grafana.openmetrics
grafana-server -config /etc/grafana.openmetrics/grafana.ini cfg:default.paths.data=/var/lib/grafana.openmetrics 1>/var/log/grafana.openmetrics.log 2>&1
