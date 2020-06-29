#!/bin/bash
cd /usr/share/grafana.dex
grafana-server -config /etc/grafana.dex/grafana.ini cfg:default.paths.data=/var/lib/grafana.dex 1>/var/log/grafana.dex.log 2>&1
