#!/bin/bash
cd /usr/share/grafana.longhorn
grafana-server -config /etc/grafana.longhorn/grafana.ini cfg:default.paths.data=/var/lib/grafana.longhorn 1>/var/log/grafana.longhorn.log 2>&1
