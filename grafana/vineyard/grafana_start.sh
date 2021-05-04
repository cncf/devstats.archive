#!/bin/bash
cd /usr/share/grafana.vineyard
grafana-server -config /etc/grafana.vineyard/grafana.ini cfg:default.paths.data=/var/lib/grafana.vineyard 1>/var/log/grafana.vineyard.log 2>&1
