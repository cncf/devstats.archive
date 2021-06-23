#!/bin/bash
cd /usr/share/grafana.pixie
grafana-server -config /etc/grafana.pixie/grafana.ini cfg:default.paths.data=/var/lib/grafana.pixie 1>/var/log/grafana.pixie.log 2>&1
