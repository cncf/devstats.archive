#!/bin/bash
cd /usr/share/grafana.zot
grafana-server -config /etc/grafana.zot/grafana.ini cfg:default.paths.data=/var/lib/grafana.zot 1>/var/log/grafana.zot.log 2>&1
