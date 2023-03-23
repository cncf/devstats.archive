#!/bin/bash
cd /usr/share/grafana.shipwright
grafana-server -config /etc/grafana.shipwright/grafana.ini cfg:default.paths.data=/var/lib/grafana.shipwright 1>/var/log/grafana.shipwright.log 2>&1
