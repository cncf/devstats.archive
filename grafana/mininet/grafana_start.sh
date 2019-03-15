#!/bin/bash
cd /usr/share/grafana.mininet
grafana-server -config /etc/grafana.mininet/grafana.ini cfg:default.paths.data=/var/lib/grafana.mininet 1>/var/log/grafana.mininet.log 2>&1
