#!/bin/sh
cd /usr/share/grafana.linkerd
grafana-server -config /etc/grafana.linkerd/grafana.ini cfg:default.paths.data=/var/lib/grafana.linkerd 1>/var/log/grafana.linkerd.log 2>&1
