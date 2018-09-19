#!/bin/bash
cd /usr/share/grafana.cortex
grafana-server -config /etc/grafana.cortex/grafana.ini cfg:default.paths.data=/var/lib/grafana.cortex 1>/var/log/grafana.cortex.log 2>&1
