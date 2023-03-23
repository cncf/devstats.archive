#!/bin/bash
cd /usr/share/grafana.ortelius
grafana-server -config /etc/grafana.ortelius/grafana.ini cfg:default.paths.data=/var/lib/grafana.ortelius 1>/var/log/grafana.ortelius.log 2>&1
