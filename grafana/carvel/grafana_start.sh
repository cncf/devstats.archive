#!/bin/bash
cd /usr/share/grafana.carvel
grafana-server -config /etc/grafana.carvel/grafana.ini cfg:default.paths.data=/var/lib/grafana.carvel 1>/var/log/grafana.carvel.log 2>&1
