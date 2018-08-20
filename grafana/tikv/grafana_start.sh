#!/bin/bash
cd /usr/share/grafana.tikv
grafana-server -config /etc/grafana.tikv/grafana.ini cfg:default.paths.data=/var/lib/grafana.tikv 1>/var/log/grafana.tikv.log 2>&1
