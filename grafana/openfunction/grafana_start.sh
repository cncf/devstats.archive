#!/bin/bash
cd /usr/share/grafana.openfunction
grafana-server -config /etc/grafana.openfunction/grafana.ini cfg:default.paths.data=/var/lib/grafana.openfunction 1>/var/log/grafana.openfunction.log 2>&1
