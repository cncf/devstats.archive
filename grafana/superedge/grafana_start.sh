#!/bin/bash
cd /usr/share/grafana.superedge
grafana-server -config /etc/grafana.superedge/grafana.ini cfg:default.paths.data=/var/lib/grafana.superedge 1>/var/log/grafana.superedge.log 2>&1
