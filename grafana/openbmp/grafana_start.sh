#!/bin/bash
cd /usr/share/grafana.openbmp
grafana-server -config /etc/grafana.openbmp/grafana.ini cfg:default.paths.data=/var/lib/grafana.openbmp 1>/var/log/grafana.openbmp.log 2>&1
