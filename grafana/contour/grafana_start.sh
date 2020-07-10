#!/bin/bash
cd /usr/share/grafana.contour
grafana-server -config /etc/grafana.contour/grafana.ini cfg:default.paths.data=/var/lib/grafana.contour 1>/var/log/grafana.contour.log 2>&1
