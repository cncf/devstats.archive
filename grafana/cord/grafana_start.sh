#!/bin/bash
cd /usr/share/grafana.cord
grafana-server -config /etc/grafana.cord/grafana.ini cfg:default.paths.data=/var/lib/grafana.cord 1>/var/log/grafana.cord.log 2>&1
