#!/bin/bash
cd /usr/share/grafana.rkt
grafana-server -config /etc/grafana.rkt/grafana.ini cfg:default.paths.data=/var/lib/grafana.rkt 1>/var/log/grafana.rkt.log 2>&1
