#!/bin/bash
cd /usr/share/grafana.k8dash
grafana-server -config /etc/grafana.k8dash/grafana.ini cfg:default.paths.data=/var/lib/grafana.k8dash 1>/var/log/grafana.k8dash.log 2>&1
