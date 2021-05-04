#!/bin/bash
cd /usr/share/grafana.wasmedge
grafana-server -config /etc/grafana.wasmedge/grafana.ini cfg:default.paths.data=/var/lib/grafana.wasmedge 1>/var/log/grafana.wasmedge.log 2>&1
