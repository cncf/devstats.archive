#!/bin/bash
cd /usr/share/grafana.krustlet
grafana-server -config /etc/grafana.krustlet/grafana.ini cfg:default.paths.data=/var/lib/grafana.krustlet 1>/var/log/grafana.krustlet.log 2>&1
