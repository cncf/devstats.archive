#!/bin/bash
cd /usr/share/grafana.devfile
grafana-server -config /etc/grafana.devfile/grafana.ini cfg:default.paths.data=/var/lib/grafana.devfile 1>/var/log/grafana.devfile.log 2>&1
