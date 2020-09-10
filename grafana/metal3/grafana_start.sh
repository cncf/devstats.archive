#!/bin/bash
cd /usr/share/grafana.metal3
grafana-server -config /etc/grafana.metal3/grafana.ini cfg:default.paths.data=/var/lib/grafana.metal3 1>/var/log/grafana.metal3.log 2>&1
