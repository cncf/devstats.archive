#!/bin/bash
cd /usr/share/grafana.aerakimesh
grafana-server -config /etc/grafana.aerakimesh/grafana.ini cfg:default.paths.data=/var/lib/grafana.aerakimesh 1>/var/log/grafana.aerakimesh.log 2>&1
