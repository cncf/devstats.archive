#!/bin/bash
cd /usr/share/grafana.parsec
grafana-server -config /etc/grafana.parsec/grafana.ini cfg:default.paths.data=/var/lib/grafana.parsec 1>/var/log/grafana.parsec.log 2>&1
