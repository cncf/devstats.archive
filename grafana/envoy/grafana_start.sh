#!/bin/bash
cd /usr/share/grafana.envoy
grafana-server -config /etc/grafana.envoy/grafana.ini cfg:default.paths.data=/var/lib/grafana.envoy 1>/var/log/grafana.envoy.log 2>&1
