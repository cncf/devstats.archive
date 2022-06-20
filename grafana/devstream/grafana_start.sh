#!/bin/bash
cd /usr/share/grafana.devstream
grafana-server -config /etc/grafana.devstream/grafana.ini cfg:default.paths.data=/var/lib/grafana.devstream 1>/var/log/grafana.devstream.log 2>&1
