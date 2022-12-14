#!/bin/bash
cd /usr/share/grafana.capsule
grafana-server -config /etc/grafana.capsule/grafana.ini cfg:default.paths.data=/var/lib/grafana.capsule 1>/var/log/grafana.capsule.log 2>&1
