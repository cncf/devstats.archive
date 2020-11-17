#!/bin/bash
cd /usr/share/grafana.pravega
grafana-server -config /etc/grafana.pravega/grafana.ini cfg:default.paths.data=/var/lib/grafana.pravega 1>/var/log/grafana.pravega.log 2>&1
