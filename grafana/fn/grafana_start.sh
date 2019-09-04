#!/bin/bash
cd /usr/share/grafana.fn
grafana-server -config /etc/grafana.fn/grafana.ini cfg:default.paths.data=/var/lib/grafana.fn 1>/var/log/grafana.fn.log 2>&1
