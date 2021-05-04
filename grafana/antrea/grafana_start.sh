#!/bin/bash
cd /usr/share/grafana.antrea
grafana-server -config /etc/grafana.antrea/grafana.ini cfg:default.paths.data=/var/lib/grafana.antrea 1>/var/log/grafana.antrea.log 2>&1
