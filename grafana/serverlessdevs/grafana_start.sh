#!/bin/bash
cd /usr/share/grafana.serverlessdevs
grafana-server -config /etc/grafana.serverlessdevs/grafana.ini cfg:default.paths.data=/var/lib/grafana.serverlessdevs 1>/var/log/grafana.serverlessdevs.log 2>&1
