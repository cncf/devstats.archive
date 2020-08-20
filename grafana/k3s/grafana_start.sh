#!/bin/bash
cd /usr/share/grafana.k3s
grafana-server -config /etc/grafana.k3s/grafana.ini cfg:default.paths.data=/var/lib/grafana.k3s 1>/var/log/grafana.k3s.log 2>&1
