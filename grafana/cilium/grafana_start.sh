#!/bin/bash
cd /usr/share/grafana.cilium
grafana-server -config /etc/grafana.cilium/grafana.ini cfg:default.paths.data=/var/lib/grafana.cilium 1>/var/log/grafana.cilium.log 2>&1
