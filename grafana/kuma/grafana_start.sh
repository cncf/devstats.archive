#!/bin/bash
cd /usr/share/grafana.kuma
grafana-server -config /etc/grafana.kuma/grafana.ini cfg:default.paths.data=/var/lib/grafana.kuma 1>/var/log/grafana.kuma.log 2>&1
