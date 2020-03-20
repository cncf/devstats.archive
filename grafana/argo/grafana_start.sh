#!/bin/bash
cd /usr/share/grafana.argo
grafana-server -config /etc/grafana.argo/grafana.ini cfg:default.paths.data=/var/lib/grafana.argo 1>/var/log/grafana.argo.log 2>&1
