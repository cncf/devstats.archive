#!/bin/bash
cd /usr/share/grafana.fabedge
grafana-server -config /etc/grafana.fabedge/grafana.ini cfg:default.paths.data=/var/lib/grafana.fabedge 1>/var/log/grafana.fabedge.log 2>&1
