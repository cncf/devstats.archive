#!/bin/bash
cd /usr/share/grafana.pyrsia
grafana-server -config /etc/grafana.pyrsia/grafana.ini cfg:default.paths.data=/var/lib/grafana.pyrsia 1>/var/log/grafana.pyrsia.log 2>&1
