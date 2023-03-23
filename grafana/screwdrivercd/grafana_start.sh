#!/bin/bash
cd /usr/share/grafana.screwdrivercd
grafana-server -config /etc/grafana.screwdrivercd/grafana.ini cfg:default.paths.data=/var/lib/grafana.screwdrivercd 1>/var/log/grafana.screwdrivercd.log 2>&1
