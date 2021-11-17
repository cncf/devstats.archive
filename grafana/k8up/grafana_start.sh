#!/bin/bash
cd /usr/share/grafana.k8up
grafana-server -config /etc/grafana.k8up/grafana.ini cfg:default.paths.data=/var/lib/grafana.k8up 1>/var/log/grafana.k8up.log 2>&1
