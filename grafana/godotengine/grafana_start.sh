#!/bin/bash
cd /usr/share/grafana.godotengine
grafana-server -config /etc/grafana.godotengine/grafana.ini cfg:default.paths.data=/var/lib/grafana.godotengine 1>/var/log/grafana.godotengine.log 2>&1
