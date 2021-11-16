#!/bin/bash
cd /usr/share/grafana.openclustermanagement
grafana-server -config /etc/grafana.openclustermanagement/grafana.ini cfg:default.paths.data=/var/lib/grafana.openclustermanagement 1>/var/log/grafana.openclustermanagement.log 2>&1
