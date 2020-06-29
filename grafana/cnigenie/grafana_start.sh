#!/bin/bash
cd /usr/share/grafana.cnigenie
grafana-server -config /etc/grafana.cnigenie/grafana.ini cfg:default.paths.data=/var/lib/grafana.cnigenie 1>/var/log/grafana.cnigenie.log 2>&1
