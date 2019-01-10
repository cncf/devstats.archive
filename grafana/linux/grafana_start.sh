#!/bin/bash
cd /usr/share/grafana.linux
grafana-server -config /etc/grafana.linux/grafana.ini cfg:default.paths.data=/var/lib/grafana.linux 1>/var/log/grafana.linux.log 2>&1
