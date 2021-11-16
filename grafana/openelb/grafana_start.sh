#!/bin/bash
cd /usr/share/grafana.openelb
grafana-server -config /etc/grafana.openelb/grafana.ini cfg:default.paths.data=/var/lib/grafana.openelb 1>/var/log/grafana.openelb.log 2>&1
