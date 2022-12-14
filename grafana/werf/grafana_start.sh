#!/bin/bash
cd /usr/share/grafana.werf
grafana-server -config /etc/grafana.werf/grafana.ini cfg:default.paths.data=/var/lib/grafana.werf 1>/var/log/grafana.werf.log 2>&1
