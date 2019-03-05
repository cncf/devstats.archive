#!/bin/bash
cd /usr/share/grafana.jenkinsx
grafana-server -config /etc/grafana.jenkinsx/grafana.ini cfg:default.paths.data=/var/lib/grafana.jenkinsx 1>/var/log/grafana.jenkinsx.log 2>&1
