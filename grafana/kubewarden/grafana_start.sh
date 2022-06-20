#!/bin/bash
cd /usr/share/grafana.kubewarden
grafana-server -config /etc/grafana.kubewarden/grafana.ini cfg:default.paths.data=/var/lib/grafana.kubewarden 1>/var/log/grafana.kubewarden.log 2>&1
