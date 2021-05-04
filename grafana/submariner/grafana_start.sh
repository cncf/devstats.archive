#!/bin/bash
cd /usr/share/grafana.submariner
grafana-server -config /etc/grafana.submariner/grafana.ini cfg:default.paths.data=/var/lib/grafana.submariner 1>/var/log/grafana.submariner.log 2>&1
