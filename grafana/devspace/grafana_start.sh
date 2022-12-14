#!/bin/bash
cd /usr/share/grafana.devspace
grafana-server -config /etc/grafana.devspace/grafana.ini cfg:default.paths.data=/var/lib/grafana.devspace 1>/var/log/grafana.devspace.log 2>&1
