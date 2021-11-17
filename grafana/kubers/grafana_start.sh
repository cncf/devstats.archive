#!/bin/bash
cd /usr/share/grafana.kubers
grafana-server -config /etc/grafana.kubers/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubers 1>/var/log/grafana.kubers.log 2>&1
