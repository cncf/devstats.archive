#!/bin/bash
cd /usr/share/grafana.servicemeshperformance
grafana-server -config /etc/grafana.servicemeshperformance/grafana.ini cfg:default.paths.data=/var/lib/grafana.servicemeshperformance 1>/var/log/grafana.servicemeshperformance.log 2>&1
