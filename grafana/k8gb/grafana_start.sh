#!/bin/bash
cd /usr/share/grafana.k8gb
grafana-server -config /etc/grafana.k8gb/grafana.ini cfg:default.paths.data=/var/lib/grafana.k8gb 1>/var/log/grafana.k8gb.log 2>&1
