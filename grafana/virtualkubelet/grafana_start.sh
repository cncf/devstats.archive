#!/bin/bash
cd /usr/share/grafana.virtualkubelet
grafana-server -config /etc/grafana.virtualkubelet/grafana.ini cfg:default.paths.data=/var/lib/grafana.virtualkubelet 1>/var/log/grafana.virtualkubelet.log 2>&1
