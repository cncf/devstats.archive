#!/bin/bash
cd /usr/share/grafana.akri
grafana-server -config /etc/grafana.akri/grafana.ini cfg:default.paths.data=/var/lib/grafana.akri 1>/var/log/grafana.akri.log 2>&1
