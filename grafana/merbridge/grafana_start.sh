#!/bin/bash
cd /usr/share/grafana.membridge
grafana-server -config /etc/grafana.membridge/grafana.ini cfg:default.paths.data=/var/lib/grafana.membridge 1>/var/log/grafana.membridge.log 2>&1
