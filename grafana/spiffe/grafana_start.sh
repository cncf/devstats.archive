#!/bin/bash
cd /usr/share/grafana.spiffe
grafana-server -config /etc/grafana.spiffe/grafana.ini cfg:default.paths.data=/var/lib/grafana.spiffe 1>/var/log/grafana.spiffe.log 2>&1
