#!/bin/bash
cd /usr/share/grafana.lima
grafana-server -config /etc/grafana.lima/grafana.ini cfg:default.paths.data=/var/lib/grafana.lima 1>/var/log/grafana.lima.log 2>&1
