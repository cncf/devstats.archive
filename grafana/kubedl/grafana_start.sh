#!/bin/bash
cd /usr/share/grafana.kubedl
grafana-server -config /etc/grafana.kubedl/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubedl 1>/var/log/grafana.kubedl.log 2>&1
