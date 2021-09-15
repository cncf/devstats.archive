#!/bin/bash
cd /usr/share/grafana.metallb
grafana-server -config /etc/grafana.metallb/grafana.ini cfg:default.paths.data=/var/lib/grafana.metallb 1>/var/log/grafana.metallb.log 2>&1
