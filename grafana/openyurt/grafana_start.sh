#!/bin/bash
cd /usr/share/grafana.openyurt
grafana-server -config /etc/grafana.openyurt/grafana.ini cfg:default.paths.data=/var/lib/grafana.openyurt 1>/var/log/grafana.openyurt.log 2>&1
