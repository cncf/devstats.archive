#!/bin/bash
cd /usr/share/grafana.openfeature
grafana-server -config /etc/grafana.openfeature/grafana.ini cfg:default.paths.data=/var/lib/grafana.openfeature 1>/var/log/grafana.openfeature.log 2>&1
