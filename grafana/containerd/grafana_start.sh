#!/bin/sh
cd /usr/share/grafana.containerd
grafana-server -config /etc/grafana.containerd/grafana.ini cfg:default.paths.data=/var/lib/grafana.containerd 1>/var/log/grafana.containerd.log 2>&1
