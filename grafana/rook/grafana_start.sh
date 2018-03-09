#!/bin/bash
cd /usr/share/grafana.rook
grafana-server -config /etc/grafana.rook/grafana.ini cfg:default.paths.data=/var/lib/grafana.rook 1>/var/log/grafana.rook.log 2>&1
