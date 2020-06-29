#!/bin/bash
cd /usr/share/grafana.kudo
grafana-server -config /etc/grafana.kudo/grafana.ini cfg:default.paths.data=/var/lib/grafana.kudo 1>/var/log/grafana.kudo.log 2>&1
