#!/bin/bash
cd /usr/share/grafana.artifacthub
grafana-server -config /etc/grafana.artifacthub/grafana.ini cfg:default.paths.data=/var/lib/grafana.artifacthub 1>/var/log/grafana.artifacthub.log 2>&1
