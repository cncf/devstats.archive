#!/bin/bash
cd /usr/share/grafana.kubevip
grafana-server -config /etc/grafana.kubevip/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubevip 1>/var/log/grafana.kubevip.log 2>&1
