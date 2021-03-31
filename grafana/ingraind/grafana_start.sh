#!/bin/bash
cd /usr/share/grafana.ingraind
grafana-server -config /etc/grafana.ingraind/grafana.ini cfg:default.paths.data=/var/lib/grafana.ingraind 1>/var/log/grafana.ingraind.log 2>&1
