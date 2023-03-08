#!/bin/bash
cd /usr/share/grafana.clusternet
grafana-server -config /etc/grafana.clusternet/grafana.ini cfg:default.paths.data=/var/lib/grafana.clusternet 1>/var/log/grafana.clusternet.log 2>&1
