#!/bin/bash
cd /usr/share/grafana.sealer
grafana-server -config /etc/grafana.sealer/grafana.ini cfg:default.paths.data=/var/lib/grafana.sealer 1>/var/log/grafana.sealer.log 2>&1
