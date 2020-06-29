#!/bin/bash
cd /usr/share/grafana.bfe
grafana-server -config /etc/grafana.bfe/grafana.ini cfg:default.paths.data=/var/lib/grafana.bfe 1>/var/log/grafana.bfe.log 2>&1
