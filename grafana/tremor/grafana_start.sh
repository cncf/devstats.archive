#!/bin/bash
cd /usr/share/grafana.tremor
grafana-server -config /etc/grafana.tremor/grafana.ini cfg:default.paths.data=/var/lib/grafana.tremor 1>/var/log/grafana.tremor.log 2>&1
