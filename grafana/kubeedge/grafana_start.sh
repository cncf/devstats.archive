#!/bin/bash
cd /usr/share/grafana.kubeedge
grafana-server -config /etc/grafana.kubeedge/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubeedge 1>/var/log/grafana.kubeedge.log 2>&1
