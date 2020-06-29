#!/bin/bash
cd /usr/share/grafana.crossplane
grafana-server -config /etc/grafana.crossplane/grafana.ini cfg:default.paths.data=/var/lib/grafana.crossplane 1>/var/log/grafana.crossplane.log 2>&1
