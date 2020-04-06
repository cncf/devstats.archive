#!/bin/bash
cd /usr/share/grafana.volcano
grafana-server -config /etc/grafana.volcano/grafana.ini cfg:default.paths.data=/var/lib/grafana.volcano 1>/var/log/grafana.volcano.log 2>&1
