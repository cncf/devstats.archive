#!/bin/bash
cd /usr/share/grafana.cii
grafana-server -config /etc/grafana.cii/grafana.ini cfg:default.paths.data=/var/lib/grafana.cii 1>/var/log/grafana.cii.log 2>&1
