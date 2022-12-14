#!/bin/bash
cd /usr/share/grafana.ko
grafana-server -config /etc/grafana.ko/grafana.ini cfg:default.paths.data=/var/lib/grafana.ko 1>/var/log/grafana.ko.log 2>&1
