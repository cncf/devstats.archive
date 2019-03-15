#!/bin/bash
cd /usr/share/grafana.openswitch
grafana-server -config /etc/grafana.openswitch/grafana.ini cfg:default.paths.data=/var/lib/grafana.openswitch 1>/var/log/grafana.openswitch.log 2>&1
