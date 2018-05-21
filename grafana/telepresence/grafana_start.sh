#!/bin/bash
cd /usr/share/grafana.telepresence
grafana-server -config /etc/grafana.telepresence/grafana.ini cfg:default.paths.data=/var/lib/grafana.telepresence 1>/var/log/grafana.telepresence.log 2>&1
