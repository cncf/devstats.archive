#!/bin/bash
cd /usr/share/grafana.tinkerbell
grafana-server -config /etc/grafana.tinkerbell/grafana.ini cfg:default.paths.data=/var/lib/grafana.tinkerbell 1>/var/log/grafana.tinkerbell.log 2>&1
