#!/bin/bash
cd /usr/share/grafana.paralus
grafana-server -config /etc/grafana.paralus/grafana.ini cfg:default.paths.data=/var/lib/grafana.paralus 1>/var/log/grafana.paralus.log 2>&1
