#!/bin/bash
cd /usr/share/grafana.curve
grafana-server -config /etc/grafana.curve/grafana.ini cfg:default.paths.data=/var/lib/grafana.curve 1>/var/log/grafana.curve.log 2>&1
