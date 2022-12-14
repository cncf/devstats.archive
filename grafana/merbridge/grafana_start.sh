#!/bin/bash
cd /usr/share/grafana.merbridge
grafana-server -config /etc/grafana.merbridge/grafana.ini cfg:default.paths.data=/var/lib/grafana.merbridge 1>/var/log/grafana.merbridge.log 2>&1
