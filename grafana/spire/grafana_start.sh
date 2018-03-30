#!/bin/bash
cd /usr/share/grafana.spire
grafana-server -config /etc/grafana.spire/grafana.ini cfg:default.paths.data=/var/lib/grafana.spire 1>/var/log/grafana.spire.log 2>&1
